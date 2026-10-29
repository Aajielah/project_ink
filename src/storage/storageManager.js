// src/storage/storageManager.js
import AsyncStorage from '@react-native-async-storage/async-storage';
import {
  calculateRemainingWeeks,
  formatNoteDate,
  getDayKey,
  getTrashDaysRemaining,
  isWeekActive,
  isWeekExpired,
  MONTH_NAMES,
  DAY_NAMES,
} from '../utils/dateUtils';

const STORAGE_KEYS = {
  PROJECTS: '@daily_notes_projects',
  MONTH_FOLDERS: '@daily_notes_months',
  WEEK_FOLDERS: '@daily_notes_weeks',
  NOTES: '@daily_notes_notes',
  TRASH: '@daily_notes_trash',
  TASKS: '@daily_notes_tasks',
  LAST_MIDNIGHT_CHECK: '@daily_notes_last_midnight_check',
};

class StorageManager {
  // ---- PROJECTS ----
  async getProjects() {
    try {
      const data = await AsyncStorage.getItem(STORAGE_KEYS.PROJECTS);
      return data ? JSON.parse(data) : [];
    } catch (e) {
      console.error('Error reading projects', e);
      return [];
    }
  }

  async createProject(name, year = new Date().getFullYear()) {
    const projects = await this.getProjects();
    const newProject = {
      id: 'proj_' + Date.now() + '_' + Math.random().toString(36).substr(2, 5),
      name: name.trim(),
      year: parseInt(year, 10) || new Date().getFullYear(),
      createdAt: new Date().toISOString(),
    };
    projects.push(newProject);
    await AsyncStorage.setItem(STORAGE_KEYS.PROJECTS, JSON.stringify(projects));
    return newProject;
  }

  async deleteProject(projectId) {
    let projects = await this.getProjects();
    projects = projects.filter((p) => p.id !== projectId);
    await AsyncStorage.setItem(STORAGE_KEYS.PROJECTS, JSON.stringify(projects));

    // Also cascade cleanup months, weeks, and notes for this project
    let months = await this.getMonthFolders();
    const monthsToDelete = months.filter((m) => m.projectId === projectId);
    months = months.filter((m) => m.projectId !== projectId);
    await AsyncStorage.setItem(STORAGE_KEYS.MONTH_FOLDERS, JSON.stringify(months));

    const monthIds = new Set(monthsToDelete.map((m) => m.id));
    let weeks = await this.getWeekFolders();
    weeks = weeks.filter((w) => !monthIds.has(w.monthFolderId));
    await AsyncStorage.setItem(STORAGE_KEYS.WEEK_FOLDERS, JSON.stringify(weeks));

    let notes = await this.getNotes();
    notes = notes.filter((n) => n.projectId !== projectId);
    await AsyncStorage.setItem(STORAGE_KEYS.NOTES, JSON.stringify(notes));

    return projects;
  }

  // ---- MONTH FOLDERS ----
  async getMonthFolders(projectId = null) {
    try {
      const data = await AsyncStorage.getItem(STORAGE_KEYS.MONTH_FOLDERS);
      const months = data ? JSON.parse(data) : [];
      if (projectId) {
        return months.filter((m) => m.projectId === projectId);
      }
      return months;
    } catch (e) {
      console.error('Error reading months', e);
      return [];
    }
  }

  /**
   * Create month folder and automatically generate remaining week folders!
   */
  async createMonthFolder(projectId, projectYear, monthIndex) {
    const months = await this.getMonthFolders();
    const monthName = MONTH_NAMES[monthIndex];

    // Check if month already exists for this project
    const existing = months.find(
      (m) => m.projectId === projectId && m.monthIndex === monthIndex
    );
    if (existing) {
      return { month: existing, alreadyExisted: true };
    }

    const newMonth = {
      id: 'month_' + Date.now() + '_' + Math.random().toString(36).substr(2, 5),
      projectId,
      monthIndex,
      monthName,
      year: projectYear,
      createdAt: new Date().toISOString(),
    };

    months.push(newMonth);
    await AsyncStorage.setItem(STORAGE_KEYS.MONTH_FOLDERS, JSON.stringify(months));

    // Now calculate and generate remaining week folders for this month
    const remainingWeeks = calculateRemainingWeeks(
      projectYear,
      monthIndex,
      new Date()
    );

    let allWeeks = await this.getWeekFolders();
    const createdWeeks = [];

    for (const wDef of remainingWeeks) {
      const newWeek = {
        id: 'week_' + Date.now() + '_' + wDef.weekNumber + '_' + Math.random().toString(36).substr(2, 4),
        monthFolderId: newMonth.id,
        projectId,
        weekNumber: wDef.weekNumber,
        label: wDef.label,
        dateRange: wDef.dateRange,
        startDay: wDef.startDay,
        endDay: wDef.endDay,
        year: projectYear,
        monthIndex,
        createdAt: new Date().toISOString(),
      };
      createdWeeks.push(newWeek);
      allWeeks.push(newWeek);
    }

    await AsyncStorage.setItem(STORAGE_KEYS.WEEK_FOLDERS, JSON.stringify(allWeeks));

    // Check if we should auto-generate today's note for the active week
    await this.autoGenerateTodayNoteIfApplicable(newMonth, createdWeeks);

    return { month: newMonth, weeks: createdWeeks, alreadyExisted: false };
  }

  // ---- WEEK FOLDERS ----
  async getWeekFolders(monthFolderId = null) {
    try {
      const data = await AsyncStorage.getItem(STORAGE_KEYS.WEEK_FOLDERS);
      const weeks = data ? JSON.parse(data) : [];
      if (monthFolderId) {
        return weeks
          .filter((w) => w.monthFolderId === monthFolderId)
          .sort((a, b) => a.weekNumber - b.weekNumber);
      }
      return weeks;
    } catch (e) {
      console.error('Error reading weeks', e);
      return [];
    }
  }

  // ---- NOTES ----
  async getNotes(weekFolderId = null) {
    try {
      const data = await AsyncStorage.getItem(STORAGE_KEYS.NOTES);
      const notes = data ? JSON.parse(data) : [];
      if (weekFolderId) {
        return notes
          .filter((n) => n.weekFolderId === weekFolderId)
          .sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));
      }
      return notes;
    } catch (e) {
      console.error('Error reading notes', e);
      return [];
    }
  }

  async getNoteById(noteId) {
    const notes = await this.getNotes();
    return notes.find((n) => n.id === noteId) || null;
  }

  /**
   * Create a note. Title is automatically the name of the day!
   */
  async createNote({
    weekFolderId,
    monthFolderId,
    projectId,
    content = '',
    customDate = new Date(),
  }) {
    const weekFolders = await this.getWeekFolders();
    const week = weekFolders.find((w) => w.id === weekFolderId);

    if (!week) {
      throw new Error('Week folder not found');
    }

    // Check if week is expired: after week is gone, no new notes can be created!
    if (isWeekExpired(week.year, week.monthIndex, week, new Date())) {
      throw new Error('This week has ended. No new notes can be created in an expired week.');
    }

    const existingNotes = await this.getNotes(weekFolderId);
    const maxAllowedNotes = week.endDay - week.startDay + 1; // normally 7 (or remaining in week 4)

    if (existingNotes.length >= maxAllowedNotes) {
      throw new Error(`This week is limited to ${maxAllowedNotes} notes.`);
    }

    const dayNumber = customDate.getDate();
    const alreadyExistsForDay = existingNotes.some((n) => n.dayNumber === dayNumber);
    if (alreadyExistsForDay) {
      throw new Error('A note for this day already exists. Notes are limited to one per day.');
    }

    const dateMeta = formatNoteDate(customDate);

    const newNote = {
      id: 'note_' + Date.now() + '_' + Math.random().toString(36).substr(2, 5),
      weekFolderId,
      monthFolderId: monthFolderId || week.monthFolderId,
      projectId: projectId || week.projectId,
      title: dateMeta.dayName, // automatically the name of that day
      dayName: dateMeta.dayName,
      dateStr: dateMeta.fullDate,
      timeStr: dateMeta.timeStr,
      dayNumber,
      content,
      createdAt: customDate.toISOString(),
      updatedAt: customDate.toISOString(),
    };

    const notes = await this.getNotes();
    notes.push(newNote);
    await AsyncStorage.setItem(STORAGE_KEYS.NOTES, JSON.stringify(notes));

    return newNote;
  }

  async updateNote(noteId, content) {
    const notes = await this.getNotes();
    const index = notes.findIndex((n) => n.id === noteId);
    if (index === -1) {
      throw new Error('Note not found');
    }

    const note = notes[index];
    const updatedMeta = formatNoteDate(new Date());

    notes[index] = {
      ...note,
      content,
      timeStr: updatedMeta.timeStr,
      updatedAt: new Date().toISOString(),
    };

    await AsyncStorage.setItem(STORAGE_KEYS.NOTES, JSON.stringify(notes));
    return notes[index];
  }

  /**
   * Delete note -> moves to Trash for 30 days!
   */
  async deleteNote(noteId) {
    let notes = await this.getNotes();
    const noteToDelete = notes.find((n) => n.id === noteId);

    if (!noteToDelete) return null;

    // Remove from active notes
    notes = notes.filter((n) => n.id !== noteId);
    await AsyncStorage.setItem(STORAGE_KEYS.NOTES, JSON.stringify(notes));

    // Add to Trash with deletedAt timestamp
    let trash = await this.getTrash();
    trash.unshift({
      ...noteToDelete,
      deletedAt: new Date().toISOString(),
    });
    await AsyncStorage.setItem(STORAGE_KEYS.TRASH, JSON.stringify(trash));

    return noteToDelete;
  }

  // ---- TRASH (30-DAY RETENTION) ----
  async getTrash() {
    try {
      const data = await AsyncStorage.getItem(STORAGE_KEYS.TRASH);
      return data ? JSON.parse(data) : [];
    } catch (e) {
      console.error('Error reading trash', e);
      return [];
    }
  }

  async restoreNote(trashNoteId) {
    let trash = await this.getTrash();
    const noteToRestore = trash.find((n) => n.id === trashNoteId);
    if (!noteToRestore) return null;

    trash = trash.filter((n) => n.id !== trashNoteId);
    await AsyncStorage.setItem(STORAGE_KEYS.TRASH, JSON.stringify(trash));

    // Remove deletedAt and put back in notes
    const { deletedAt, ...restoredNote } = noteToRestore;
    const notes = await this.getNotes();
    notes.push(restoredNote);
    await AsyncStorage.setItem(STORAGE_KEYS.NOTES, JSON.stringify(notes));

    return restoredNote;
  }

  async permanentlyDeleteNote(trashNoteId) {
    let trash = await this.getTrash();
    trash = trash.filter((n) => n.id !== trashNoteId);
    await AsyncStorage.setItem(STORAGE_KEYS.TRASH, JSON.stringify(trash));
    return trash;
  }

  async emptyTrash() {
    await AsyncStorage.setItem(STORAGE_KEYS.TRASH, JSON.stringify([]));
    return [];
  }

  /**
   * Automatically purges trash notes that have been in trash for more than 30 days.
   */
  async purgeExpiredTrash() {
    const trash = await this.getTrash();
    const now = new Date();
    const remaining = trash.filter((note) => {
      const daysLeft = getTrashDaysRemaining(note.deletedAt, now);
      return daysLeft > 0;
    });

    if (remaining.length !== trash.length) {
      await AsyncStorage.setItem(STORAGE_KEYS.TRASH, JSON.stringify(remaining));
    }
    return remaining;
  }

  // ---- AUTO-GENERATE TODAY'S NOTE FOR ACTIVE WEEK ----
  async autoGenerateTodayNoteIfApplicable(month, weeksList) {
    try {
      const now = new Date();
      if (now.getFullYear() !== month.year || now.getMonth() !== month.monthIndex) {
        return;
      }

      const dayNumber = now.getDate();
      const activeWeek = weeksList.find(
        (w) => dayNumber >= w.startDay && dayNumber <= w.endDay
      );

      if (!activeWeek) return;

      const weekNotes = await this.getNotes(activeWeek.id);
      // Check if note for today's date already exists
      const dateMeta = formatNoteDate(now);
      const exists = weekNotes.some(
        (n) => n.dayNumber === dayNumber || n.dateStr === dateMeta.fullDate
      );

      if (!exists) {
        await this.createNote({
          weekFolderId: activeWeek.id,
          monthFolderId: month.id,
          projectId: month.projectId,
          content: '',
          customDate: now,
        });
      }
    } catch (e) {
      console.error('Error auto-generating today note', e);
    }
  }

  /**
   * Run background check for all active weeks across all months/projects
   * to ensure a note is auto-generated for the current day.
   */
  async ensureDailyNotesGenerated() {
    try {
      const now = new Date();
      const currentYear = now.getFullYear();
      const currentMonth = now.getMonth();
      const currentDay = now.getDate();

      const months = await this.getMonthFolders();
      const activeMonths = months.filter(
        (m) => m.year === currentYear && m.monthIndex === currentMonth
      );

      for (const m of activeMonths) {
        const weeks = await this.getWeekFolders(m.id);
        const activeWeek = weeks.find(
          (w) => currentDay >= w.startDay && currentDay <= w.endDay
        );
        if (activeWeek) {
          const notes = await this.getNotes(activeWeek.id);
          const hasTodayNote = notes.some((n) => n.dayNumber === currentDay);
          if (!hasTodayNote && notes.length < (activeWeek.endDay - activeWeek.startDay + 1)) {
            await this.createNote({
              weekFolderId: activeWeek.id,
              monthFolderId: m.id,
              projectId: m.projectId,
              content: '',
              customDate: now,
            });
          }
        }
      }
    } catch (e) {
      console.error('ensureDailyNotesGenerated error', e);
    }
  }

  // ---- TASKS SYSTEM ----
  async getTasks() {
    try {
      const data = await AsyncStorage.getItem(STORAGE_KEYS.TASKS);
      return data ? JSON.parse(data) : [];
    } catch (e) {
      console.error('Error reading tasks', e);
      return [];
    }
  }

  async createTask({ text, repeat = 'none', weeklyDay = 1 }) {
    const tasks = await this.getTasks();
    const newTask = {
      id: 'task_' + Date.now() + '_' + Math.random().toString(36).substr(2, 5),
      text: text.trim(),
      completed: false,
      completedAt: null,
      repeat, // 'none' | 'daily' | 'weekly'
      weeklyDay: repeat === 'weekly' ? weeklyDay : null, // 0 = Sunday, 1 = Monday, etc.
      createdAt: new Date().toISOString(),
    };
    tasks.unshift(newTask);
    await AsyncStorage.setItem(STORAGE_KEYS.TASKS, JSON.stringify(tasks));
    return newTask;
  }

  async toggleTask(taskId) {
    const tasks = await this.getTasks();
    const index = tasks.findIndex((t) => t.id === taskId);
    if (index === -1) return null;

    const current = tasks[index];
    const willBeCompleted = !current.completed;

    tasks[index] = {
      ...current,
      completed: willBeCompleted,
      completedAt: willBeCompleted ? new Date().toISOString() : null,
    };

    await AsyncStorage.setItem(STORAGE_KEYS.TASKS, JSON.stringify(tasks));
    return tasks[index];
  }

  async deleteTask(taskId) {
    let tasks = await this.getTasks();
    tasks = tasks.filter((t) => t.id !== taskId);
    await AsyncStorage.setItem(STORAGE_KEYS.TASKS, JSON.stringify(tasks));
    return tasks;
  }

  /**
   * Midnight Reset logic:
   * Runs whenever the app opens or crosses midnight.
   * - One-off completed tasks (repeat === 'none') are cleared/deleted.
   * - Daily repeat completed tasks (repeat === 'daily') uncross/reset to false.
   * - Weekly repeat tasks uncross/reset on their chosen day of the week.
   */
  async runMidnightTaskReset() {
    try {
      const todayKey = getDayKey(new Date());
      const lastCheck = await AsyncStorage.getItem(STORAGE_KEYS.LAST_MIDNIGHT_CHECK);

      // If already checked today, nothing new to reset
      if (lastCheck === todayKey) {
        return;
      }

      const tasks = await this.getTasks();
      const currentDayOfWeek = new Date().getDay(); // 0 = Sunday, 1 = Monday, etc.
      const updatedTasks = [];

      for (const task of tasks) {
        if (!task.completed) {
          // Incomplete tasks always stay as-is
          updatedTasks.push(task);
          continue;
        }

        // Task was completed:
        if (task.repeat === 'none') {
          // Automatically cleared! Do not include in updatedTasks
          continue;
        } else if (task.repeat === 'daily') {
          // Uncheck and renew for the new day
          updatedTasks.push({
            ...task,
            completed: false,
            completedAt: null,
          });
        } else if (task.repeat === 'weekly') {
          // If today is the designated weekly day, respawn/renew
          if (task.weeklyDay === currentDayOfWeek) {
            updatedTasks.push({
              ...task,
              completed: false,
              completedAt: null,
            });
          } else {
            // Keep completed until that specific weekly day arrives
            updatedTasks.push(task);
          }
        }
      }

      await AsyncStorage.setItem(STORAGE_KEYS.TASKS, JSON.stringify(updatedTasks));
      await AsyncStorage.setItem(STORAGE_KEYS.LAST_MIDNIGHT_CHECK, todayKey);
    } catch (e) {
      console.error('Error during midnight reset', e);
    }
  }

  // ---- EXPORT & IMPORT ----
  async exportAllData() {
    const projects = await this.getProjects();
    const monthFolders = await this.getMonthFolders();
    const weekFolders = await this.getWeekFolders();
    const notes = await this.getNotes();
    const trash = await this.getTrash();
    const tasks = await this.getTasks();

    const payload = {
      version: 1,
      appName: 'Daily Notes',
      exportedAt: new Date().toISOString(),
      data: {
        projects,
        monthFolders,
        weekFolders,
        notes,
        trash,
        tasks,
      },
    };

    return JSON.stringify(payload, null, 2);
  }

  async importAllData(jsonString) {
    try {
      const parsed = JSON.parse(jsonString);
      if (!parsed.data) {
        throw new Error('Invalid Daily Notes backup format');
      }

      const { projects, monthFolders, weekFolders, notes, trash, tasks } = parsed.data;

      if (projects) await AsyncStorage.setItem(STORAGE_KEYS.PROJECTS, JSON.stringify(projects));
      if (monthFolders) await AsyncStorage.setItem(STORAGE_KEYS.MONTH_FOLDERS, JSON.stringify(monthFolders));
      if (weekFolders) await AsyncStorage.setItem(STORAGE_KEYS.WEEK_FOLDERS, JSON.stringify(weekFolders));
      if (notes) await AsyncStorage.setItem(STORAGE_KEYS.NOTES, JSON.stringify(notes));
      if (trash) await AsyncStorage.setItem(STORAGE_KEYS.TRASH, JSON.stringify(trash));
      if (tasks) await AsyncStorage.setItem(STORAGE_KEYS.TASKS, JSON.stringify(tasks));

      return { success: true };
    } catch (e) {
      console.error('Import error', e);
      return { success: false, error: e.message };
    }
  }
}

export const storage = new StorageManager();
