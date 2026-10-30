// src/screens/HomeScreen.js
import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  FlatList,
  Modal,
  TextInput,
  StyleSheet,
  Alert,
  BackHandler,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useTheme } from '../theme/ThemeContext';
import { storage } from '../storage/storageManager';
import { isWeekActive, isWeekExpired } from '../utils/dateUtils';
import WeekNotesScreen from './WeekNotesScreen';
import NoteEditorScreen from './NoteEditorScreen';

export default function HomeScreen() {
  const { theme } = useTheme();
  // Navigation stack state: 'projects' | 'months' | 'weeks' | 'weekNotes' | 'noteEditor'
  const [currentLevel, setCurrentLevel] = useState('projects');
  const [selectedProject, setSelectedProject] = useState(null);
  const [selectedMonth, setSelectedMonth] = useState(null);
  const [selectedWeek, setSelectedWeek] = useState(null);
  const [selectedNoteId, setSelectedNoteId] = useState(null);

  // Data lists
  const [projects, setProjects] = useState([]);
  const [monthFolders, setMonthFolders] = useState([]);
  const [weekFolders, setWeekFolders] = useState([]);

  // Modals
  const [showProjectModal, setShowProjectModal] = useState(false);
  const [projectNameInput, setProjectNameInput] = useState('');

  // ANDROID HARDWARE BACK HANDLER
  useEffect(() => {
    const backAction = () => {
      if (showProjectModal) {
        setShowProjectModal(false);
        return true;
      }
      if (currentLevel === 'noteEditor') {
        setCurrentLevel('weekNotes');
        setSelectedNoteId(null);
        return true;
      }
      if (currentLevel === 'weekNotes') {
        setCurrentLevel('weeks');
        return true;
      }
      if (currentLevel === 'weeks') {
        setCurrentLevel('months');
        return true;
      }
      if (currentLevel === 'months') {
        setCurrentLevel('projects');
        return true;
      }
      return false; // Root level: lets Android handle exit
    };

    const backHandler = BackHandler.addEventListener(
      'hardwareBackPress',
      backAction
    );

    return () => backHandler.remove();
  }, [currentLevel, showProjectModal]);

  useEffect(() => {
    loadProjects();
    storage.ensureDailyNotesGenerated();
    storage.purgeExpiredTrash();
    storage.runMidnightTaskReset();
  }, []);

  const loadProjects = async () => {
    const list = await storage.getProjects();
    setProjects(list);
  };

  const loadMonths = async (proj) => {
    const list = await storage.ensureAndGetActiveMonths(proj);
    setMonthFolders(list);
  };

  const loadWeeks = async (month) => {
    const list = await storage.getWeekFolders(month.id);
    setWeekFolders(list);
  };

  // ---- PROJECT CREATION ----
  const handleCreateProject = async () => {
    if (!projectNameInput.trim()) {
      Alert.alert('Required', 'Please enter a project name.');
      return;
    }
    const name = projectNameInput.trim();
    const extractedYear = parseInt(name, 10) || new Date().getFullYear();
    const created = await storage.createProject(name, extractedYear);
    setProjectNameInput('');
    setShowProjectModal(false);
    await loadProjects();
    openProject(created);
  };

  const openProject = async (proj) => {
    setSelectedProject(proj);
    await loadMonths(proj);
    setCurrentLevel('months');
  };

  const handleDeleteProject = (projId, e) => {
    e.stopPropagation();
    Alert.alert(
      'Delete Project',
      'Are you sure you want to delete this project and all its notes?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            await storage.deleteProject(projId);
            await loadProjects();
          },
        },
      ]
    );
  };

  const openMonth = async (month) => {
    setSelectedMonth(month);
    await loadWeeks(month);
    setCurrentLevel('weeks');
  };

  const openWeek = (week) => {
    setSelectedWeek(week);
    setCurrentLevel('weekNotes');
  };

  const openNoteEditor = (noteId) => {
    setSelectedNoteId(noteId);
    setCurrentLevel('noteEditor');
  };

  // -------------------------------------------------------------
  // RENDER LEVEL: Note Editor
  // -------------------------------------------------------------
  if (currentLevel === 'noteEditor') {
    return (
      <NoteEditorScreen
        noteId={selectedNoteId}
        onBack={() => {
          setCurrentLevel('weekNotes');
          setSelectedNoteId(null);
        }}
        onDeleted={() => {
          setCurrentLevel('weekNotes');
          setSelectedNoteId(null);
        }}
      />
    );
  }

  // -------------------------------------------------------------
  // RENDER LEVEL: Week Notes List
  // -------------------------------------------------------------
  if (currentLevel === 'weekNotes') {
    return (
      <WeekNotesScreen
        week={selectedWeek}
        month={selectedMonth}
        project={selectedProject}
        onBack={() => setCurrentLevel('weeks')}
        onSelectNote={openNoteEditor}
      />
    );
  }

  // -------------------------------------------------------------
  // RENDER LEVEL: Week Folders inside a Month
  // -------------------------------------------------------------
  if (currentLevel === 'weeks') {
    return (
      <View style={[styles.container, { backgroundColor: theme.background }]}>
        <View style={[styles.header, { backgroundColor: theme.surface, borderBottomColor: theme.border }]}>
          <TouchableOpacity
            style={styles.backBtn}
            onPress={() => setCurrentLevel('months')}
          >
            <Ionicons name="arrow-back" size={24} color={theme.text} />
          </TouchableOpacity>
          <View style={styles.headerTitles}>
            <Text style={[styles.headerTitle, { color: theme.text }]}>{selectedMonth?.monthName}</Text>
            <Text style={[styles.headerSubtitle, { color: theme.textSecondary }]}>
              {selectedProject?.name} • {weekFolders.length} Week Folders
            </Text>
          </View>
        </View>

        <FlatList
          data={weekFolders}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.listContainer}
          renderItem={({ item }) => {
            const active = isWeekActive(item.year, item.monthIndex, item, new Date());
            const expired = isWeekExpired(item.year, item.monthIndex, item, new Date());

            return (
              <TouchableOpacity
                style={[
                  styles.card,
                  { backgroundColor: theme.card, borderColor: theme.border },
                  active && { borderColor: theme.secondary, borderWidth: 1.5 },
                ]}
                activeOpacity={0.7}
                onPress={() => openWeek(item)}
              >
                <View style={styles.cardHeader}>
                  <View style={[styles.iconCircle, { backgroundColor: theme.surfaceHover }]}>
                    <Ionicons
                      name="folder"
                      size={24}
                      color={active ? theme.secondary : theme.primary}
                    />
                  </View>
                  <View style={styles.cardMainInfo}>
                    <Text style={[styles.cardTitle, { color: theme.text }]}>{item.label}</Text>
                    <Text style={[styles.cardSubtitle, { color: theme.textSecondary }]}>{item.dateRange}</Text>
                  </View>
                  {active ? (
                    <View style={[styles.badgeActive, { backgroundColor: theme.secondaryLight }]}>
                      <Text style={[styles.badgeActiveText, { color: theme.secondary }]}>Active</Text>
                    </View>
                  ) : expired ? (
                    <View style={[styles.badgeExpired, { backgroundColor: theme.surfaceHover }]}>
                      <Text style={[styles.badgeExpiredText, { color: theme.textMuted }]}>Ended</Text>
                    </View>
                  ) : null}
                  <Ionicons name="chevron-forward" size={20} color={theme.textMuted} />
                </View>
              </TouchableOpacity>
            );
          }}
          ListEmptyComponent={
            <View style={styles.emptyContainer}>
              <Ionicons name="calendar-outline" size={48} color={theme.textMuted} />
              <Text style={[styles.emptyTitle, { color: theme.text }]}>No remaining weeks in this month</Text>
            </View>
          }
        />
      </View>
    );
  }

  // -------------------------------------------------------------
  // RENDER LEVEL: Months inside a Project (Strictly active months)
  // -------------------------------------------------------------
  if (currentLevel === 'months') {
    return (
      <View style={[styles.container, { backgroundColor: theme.background }]}>
        <View style={[styles.header, { backgroundColor: theme.surface, borderBottomColor: theme.border }]}>
          <TouchableOpacity
            style={styles.backBtn}
            onPress={() => setCurrentLevel('projects')}
          >
            <Ionicons name="arrow-back" size={24} color={theme.text} />
          </TouchableOpacity>
          <View style={styles.headerTitles}>
            <Text style={[styles.headerTitle, { color: theme.text }]}>{selectedProject?.name}</Text>
            <Text style={[styles.headerSubtitle, { color: theme.textSecondary }]}>
              Year {selectedProject?.year} • Active Months
            </Text>
          </View>
        </View>

        <FlatList
          data={monthFolders}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.listContainer}
          renderItem={({ item }) => {
            const currentMonthIdx = new Date().getMonth();
            const isCurrent = item.monthIndex === currentMonthIdx;

            return (
              <TouchableOpacity
                style={[
                  styles.card,
                  { backgroundColor: theme.card, borderColor: theme.border },
                  isCurrent && { borderColor: theme.secondary, borderWidth: 1.5 },
                ]}
                activeOpacity={0.7}
                onPress={() => openMonth(item)}
              >
                <View style={styles.cardHeader}>
                  <View style={[styles.iconCircle, { backgroundColor: theme.surfaceHover }]}>
                    <Ionicons
                      name="calendar"
                      size={24}
                      color={isCurrent ? theme.secondary : theme.primary}
                    />
                  </View>
                  <View style={styles.cardMainInfo}>
                    <Text style={[styles.cardTitle, { color: theme.text }]}>{item.monthName}</Text>
                    <Text style={[styles.cardSubtitle, { color: theme.textSecondary }]}>
                      {isCurrent ? 'Current Active Month' : 'Completed Month'}
                    </Text>
                  </View>
                  {isCurrent && (
                    <View style={[styles.badgeActive, { backgroundColor: theme.secondaryLight }]}>
                      <Text style={[styles.badgeActiveText, { color: theme.secondary }]}>Active</Text>
                    </View>
                  )}
                  <Ionicons name="chevron-forward" size={20} color={theme.textMuted} />
                </View>
              </TouchableOpacity>
            );
          }}
          ListEmptyComponent={
            <View style={styles.emptyContainer}>
              <Ionicons name="calendar-outline" size={48} color={theme.textMuted} />
              <Text style={[styles.emptyTitle, { color: theme.text }]}>No active months found</Text>
            </View>
          }
        />
      </View>
    );
  }

  // -------------------------------------------------------------
  // RENDER LEVEL: Projects (Main Home View)
  // -------------------------------------------------------------
  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <View style={[styles.header, { backgroundColor: theme.surface, borderBottomColor: theme.border }]}>
        <View style={styles.headerTitles}>
          <Text style={[styles.headerTitle, { color: theme.text }]}>Daily Notes</Text>
          <Text style={[styles.headerSubtitle, { color: theme.textSecondary }]}>Projects</Text>
        </View>
      </View>

      <FlatList
        data={projects}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.listContainer}
        renderItem={({ item }) => (
          <TouchableOpacity
            style={[styles.card, { backgroundColor: theme.card, borderColor: theme.border }]}
            activeOpacity={0.7}
            onPress={() => openProject(item)}
          >
            <View style={styles.cardHeader}>
              <View style={[styles.iconCircle, { backgroundColor: theme.surfaceHover }]}>
                <Ionicons name="folder-open" size={24} color={theme.primary} />
              </View>
              <View style={styles.cardMainInfo}>
                <Text style={[styles.cardTitle, { color: theme.text }]}>{item.name}</Text>
                <Text style={[styles.cardSubtitle, { color: theme.textSecondary }]}>Year {item.year}</Text>
              </View>
              <TouchableOpacity
                style={styles.cardDeleteBtn}
                onPress={(e) => handleDeleteProject(item.id, e)}
              >
                <Ionicons name="trash-outline" size={18} color={theme.textMuted} />
              </TouchableOpacity>
              <Ionicons name="chevron-forward" size={20} color={theme.textMuted} />
            </View>
          </TouchableOpacity>
        )}
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Ionicons name="folder-outline" size={48} color={theme.textMuted} />
            <Text style={[styles.emptyTitle, { color: theme.text }]}>No projects created yet</Text>
            <Text style={[styles.emptySub, { color: theme.textMuted }]}>
              Tap the big + button below and name your project (e.g. 2026).
            </Text>
          </View>
        }
      />

      <TouchableOpacity
        style={[styles.fab, { backgroundColor: theme.primary }]}
        activeOpacity={0.8}
        onPress={() => setShowProjectModal(true)}
      >
        <Ionicons name="add" size={32} color="#FFFFFF" />
      </TouchableOpacity>

      <Modal
        visible={showProjectModal}
        transparent
        animationType="fade"
        onRequestClose={() => setShowProjectModal(false)}
      >
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          style={styles.modalOverlay}
        >
          <View style={[styles.modalBox, { backgroundColor: theme.surface, borderColor: theme.border }]}>
            <Text style={[styles.modalTitle, { color: theme.text }]}>New Project</Text>
            <Text style={[styles.modalSubtitle, { color: theme.textSecondary }]}>
              Enter your project name (e.g. 2026). The active month will be generated automatically.
            </Text>

            <TextInput
              style={[
                styles.modalInput,
                { backgroundColor: theme.background, borderColor: theme.border, color: theme.text },
              ]}
              placeholder="e.g. 2026"
              placeholderTextColor={theme.textMuted}
              value={projectNameInput}
              onChangeText={setProjectNameInput}
              autoFocus
            />

            <View style={styles.modalButtons}>
              <TouchableOpacity
                style={styles.modalCancelBtn}
                onPress={() => {
                  setProjectNameInput('');
                  setShowProjectModal(false);
                }}
              >
                <Text style={[styles.modalCancelText, { color: theme.textSecondary }]}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalConfirmBtn, { backgroundColor: theme.primary }]}
                onPress={handleCreateProject}
              >
                <Text style={styles.modalConfirmText}>Create</Text>
              </TouchableOpacity>
            </View>
          </View>
        </KeyboardAvoidingView>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderBottomWidth: 1,
  },
  backBtn: {
    padding: 6,
    marginRight: 10,
  },
  headerTitles: {
    flex: 1,
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: '700',
  },
  headerSubtitle: {
    fontSize: 12,
    marginTop: 2,
  },
  listContainer: {
    padding: 16,
    paddingBottom: 90,
  },
  card: {
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    borderWidth: 1,
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  iconCircle: {
    width: 44,
    height: 44,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 14,
  },
  cardMainInfo: {
    flex: 1,
  },
  cardTitle: {
    fontSize: 16,
    fontWeight: '700',
  },
  cardSubtitle: {
    fontSize: 12,
    marginTop: 2,
  },
  cardDeleteBtn: {
    padding: 8,
    marginRight: 4,
  },
  badgeActive: {
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 8,
    marginRight: 8,
  },
  badgeActiveText: {
    fontSize: 11,
    fontWeight: '600',
  },
  badgeExpired: {
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 8,
    marginRight: 8,
  },
  badgeExpiredText: {
    fontSize: 11,
  },
  emptyContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 70,
  },
  emptyTitle: {
    fontSize: 16,
    fontWeight: '600',
    marginTop: 12,
  },
  emptySub: {
    fontSize: 13,
    textAlign: 'center',
    marginTop: 6,
    paddingHorizontal: 30,
  },
  fab: {
    position: 'absolute',
    bottom: 24,
    right: 24,
    width: 60,
    height: 60,
    borderRadius: 30,
    alignItems: 'center',
    justifyContent: 'center',
    elevation: 6,
    shadowColor: '#000',
    shadowOpacity: 0.25,
    shadowRadius: 5,
    shadowOffset: { width: 0, height: 3 },
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.6)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
  modalBox: {
    width: '100%',
    borderRadius: 16,
    padding: 20,
    borderWidth: 1,
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: '700',
  },
  modalSubtitle: {
    fontSize: 13,
    marginTop: 4,
    marginBottom: 16,
    lineHeight: 18,
  },
  modalInput: {
    borderRadius: 8,
    paddingHorizontal: 14,
    paddingVertical: 12,
    fontSize: 15,
    borderWidth: 1,
    marginBottom: 20,
  },
  modalButtons: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: 12,
  },
  modalCancelBtn: {
    paddingVertical: 10,
    paddingHorizontal: 16,
    borderRadius: 8,
  },
  modalCancelText: {
    fontWeight: '600',
  },
  modalConfirmBtn: {
    paddingVertical: 10,
    paddingHorizontal: 20,
    borderRadius: 8,
  },
  modalConfirmText: {
    color: '#FFFFFF',
    fontWeight: '700',
  },
});
