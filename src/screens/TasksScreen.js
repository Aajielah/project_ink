// src/screens/TasksScreen.js
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
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useTheme } from '../theme/ThemeContext';
import { storage } from '../storage/storageManager';
import { DAY_NAMES } from '../utils/dateUtils';

export default function TasksScreen() {
  const { theme } = useTheme();
  const [tasks, setTasks] = useState([]);

  // Create Modal State
  const [showModal, setShowModal] = useState(false);
  const [taskText, setTaskText] = useState('');
  const [repeatMode, setRepeatMode] = useState('none'); // 'none' | 'daily' | 'weekly'
  const [weeklyDay, setWeeklyDay] = useState(1); // 1 = Monday

  // Edit Modal State
  const [editingTask, setEditingTask] = useState(null);
  const [editText, setEditText] = useState('');
  const [editRepeatMode, setEditRepeatMode] = useState('none');
  const [editWeeklyDay, setEditWeeklyDay] = useState(1);

  useEffect(() => {
    loadTasks();
    storage.runMidnightTaskReset().then(() => loadTasks());
  }, []);

  // ANDROID HARDWARE BACK HANDLER
  useEffect(() => {
    const onBackPress = () => {
      if (editingTask) {
        setEditingTask(null);
        return true;
      }
      if (showModal) {
        setShowModal(false);
        return true;
      }
      return false; // Root tasks: lets parent tab or Android handle
    };

    const backHandler = BackHandler.addEventListener('hardwareBackPress', onBackPress);
    return () => backHandler.remove();
  }, [editingTask, showModal]);

  const loadTasks = async () => {
    const list = await storage.getTasks();
    setTasks(list);
  };

  const handleCreateTask = async () => {
    if (!taskText.trim()) {
      Alert.alert('Required', 'Please enter task description.');
      return;
    }

    await storage.createTask({
      text: taskText,
      repeat: repeatMode,
      weeklyDay: repeatMode === 'weekly' ? weeklyDay : null,
    });

    setTaskText('');
    setRepeatMode('none');
    setShowModal(false);
    await loadTasks();
  };

  const openEditModal = (task) => {
    setEditingTask(task);
    setEditText(task.text);
    setEditRepeatMode(task.repeat || 'none');
    setEditWeeklyDay(task.weeklyDay !== null ? task.weeklyDay : 1);
  };

  const handleSaveEdit = async () => {
    if (!editText.trim()) {
      Alert.alert('Required', 'Please enter task description.');
      return;
    }

    await storage.updateTask(editingTask.id, {
      text: editText,
      repeat: editRepeatMode,
      weeklyDay: editRepeatMode === 'weekly' ? editWeeklyDay : null,
    });

    setEditingTask(null);
    await loadTasks();
  };

  const handleToggle = async (taskId) => {
    await storage.toggleTask(taskId);
    await loadTasks();
  };

  const handleDelete = async (taskId) => {
    await storage.deleteTask(taskId);
    await loadTasks();
  };

  const renderTaskItem = ({ item }) => {
    const isCompleted = item.completed;

    return (
      <View
        style={[
          styles.taskCard,
          {
            backgroundColor: isCompleted ? theme.surfaceHover : theme.card,
            borderColor: theme.border,
          },
          isCompleted && styles.taskCardCompleted,
        ]}
      >
        <TouchableOpacity
          style={styles.checkboxTouch}
          onPress={() => handleToggle(item.id)}
        >
          <Ionicons
            name={isCompleted ? 'checkbox' : 'square-outline'}
            size={24}
            color={isCompleted ? theme.secondary : theme.textSecondary}
          />
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.taskContent}
          activeOpacity={0.7}
          onPress={() => openEditModal(item)}
        >
          <Text
            style={[
              styles.taskText,
              { color: isCompleted ? theme.textMuted : theme.text },
              isCompleted && styles.taskTextCompleted,
            ]}
          >
            {item.text}
          </Text>

          <View style={styles.badgeRow}>
            {item.repeat === 'daily' && (
              <View style={[styles.repeatBadge, { backgroundColor: theme.surfaceHover, borderColor: theme.border }]}>
                <Ionicons name="repeat" size={12} color={theme.primary} />
                <Text style={[styles.repeatBadgeText, { color: theme.primary }]}>Daily Repeat</Text>
              </View>
            )}
            {item.repeat === 'weekly' && (
              <View style={[styles.repeatBadge, { backgroundColor: theme.surfaceHover, borderColor: theme.border }]}>
                <Ionicons name="calendar-outline" size={12} color={theme.warning} />
                <Text style={[styles.repeatBadgeText, { color: theme.warning }]}>
                  Weekly ({DAY_NAMES[item.weeklyDay]?.slice(0, 3)})
                </Text>
              </View>
            )}
            {item.repeat === 'none' && (
              <Text style={[styles.oneOffText, { color: theme.textMuted }]}>Clears at 12 AM</Text>
            )}
          </View>
        </TouchableOpacity>

        <View style={styles.actionBtns}>
          <TouchableOpacity
            style={styles.iconBtn}
            onPress={() => openEditModal(item)}
          >
            <Ionicons name="pencil-outline" size={18} color={theme.textSecondary} />
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.iconBtn}
            onPress={() => handleDelete(item.id)}
          >
            <Ionicons name="close-circle-outline" size={20} color={theme.textMuted} />
          </TouchableOpacity>
        </View>
      </View>
    );
  };

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      {/* Header */}
      <View style={[styles.header, { backgroundColor: theme.surface, borderBottomColor: theme.border }]}>
        <View style={styles.headerTitles}>
          <Text style={[styles.headerTitle, { color: theme.text }]}>Tasks</Text>
          <Text style={[styles.headerSubtitle, { color: theme.textSecondary }]}>
            Tap pencil or task text to edit name and recurrence
          </Text>
        </View>
      </View>

      {/* Task List */}
      <FlatList
        data={tasks}
        keyExtractor={(item) => item.id}
        renderItem={renderTaskItem}
        contentContainerStyle={styles.listContainer}
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Ionicons name="checkbox-outline" size={48} color={theme.textMuted} />
            <Text style={[styles.emptyTitle, { color: theme.text }]}>No tasks yet</Text>
            <Text style={[styles.emptySub, { color: theme.textMuted }]}>
              Tap the big + button below to add your daily or recurring tasks.
            </Text>
          </View>
        }
      />

      {/* Floating Plus Button */}
      <TouchableOpacity
        style={[styles.fab, { backgroundColor: theme.primary }]}
        activeOpacity={0.8}
        onPress={() => setShowModal(true)}
      >
        <Ionicons name="add" size={32} color="#FFFFFF" />
      </TouchableOpacity>

      {/* CREATE TASK MODAL */}
      <Modal
        visible={showModal}
        transparent
        animationType="fade"
        onRequestClose={() => setShowModal(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={[styles.modalBox, { backgroundColor: theme.surface, borderColor: theme.border }]}>
            <Text style={[styles.modalTitle, { color: theme.text }]}>New Task</Text>

            <TextInput
              style={[
                styles.modalInput,
                { backgroundColor: theme.background, borderColor: theme.border, color: theme.text },
              ]}
              placeholder="What do you need to do?"
              placeholderTextColor={theme.textMuted}
              value={taskText}
              onChangeText={setTaskText}
              autoFocus
            />

            <Text style={[styles.repeatLabel, { color: theme.textSecondary }]}>Repeat Schedule:</Text>
            <View style={styles.repeatTabs}>
              <TouchableOpacity
                style={[
                  styles.repeatTab,
                  { backgroundColor: theme.background, borderColor: theme.border },
                  repeatMode === 'none' && { backgroundColor: theme.primaryLight, borderColor: theme.primary },
                ]}
                onPress={() => setRepeatMode('none')}
              >
                <Text
                  style={[
                    styles.repeatTabText,
                    { color: repeatMode === 'none' ? theme.primary : theme.textSecondary },
                  ]}
                >
                  Once (Clear at 12 AM)
                </Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[
                  styles.repeatTab,
                  { backgroundColor: theme.background, borderColor: theme.border },
                  repeatMode === 'daily' && { backgroundColor: theme.primaryLight, borderColor: theme.primary },
                ]}
                onPress={() => setRepeatMode('daily')}
              >
                <Text
                  style={[
                    styles.repeatTabText,
                    { color: repeatMode === 'daily' ? theme.primary : theme.textSecondary },
                  ]}
                >
                  Daily Repeat
                </Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[
                  styles.repeatTab,
                  { backgroundColor: theme.background, borderColor: theme.border },
                  repeatMode === 'weekly' && { backgroundColor: theme.primaryLight, borderColor: theme.primary },
                ]}
                onPress={() => setRepeatMode('weekly')}
              >
                <Text
                  style={[
                    styles.repeatTabText,
                    { color: repeatMode === 'weekly' ? theme.primary : theme.textSecondary },
                  ]}
                >
                  Weekly Repeat
                </Text>
              </TouchableOpacity>
            </View>

            {repeatMode === 'weekly' && (
              <View style={styles.weeklyPicker}>
                <Text style={[styles.subLabel, { color: theme.textSecondary }]}>Choose Day to Respawn:</Text>
                <View style={styles.daysRow}>
                  {DAY_NAMES.map((dName, dIdx) => (
                    <TouchableOpacity
                      key={dName}
                      style={[
                        styles.dayCircle,
                        { backgroundColor: theme.background, borderColor: theme.border },
                        weeklyDay === dIdx && { backgroundColor: theme.primary, borderColor: theme.primary },
                      ]}
                      onPress={() => setWeeklyDay(dIdx)}
                    >
                      <Text
                        style={[
                          styles.dayCircleText,
                          { color: weeklyDay === dIdx ? '#FFFFFF' : theme.text },
                        ]}
                      >
                        {dName[0]}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </View>
              </View>
            )}

            <View style={styles.modalButtons}>
              <TouchableOpacity
                style={styles.modalCancelBtn}
                onPress={() => setShowModal(false)}
              >
                <Text style={[styles.modalCancelText, { color: theme.textSecondary }]}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalConfirmBtn, { backgroundColor: theme.primary }]}
                onPress={handleCreateTask}
              >
                <Text style={styles.modalConfirmText}>Add Task</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      {/* EDIT TASK MODAL */}
      <Modal
        visible={!!editingTask}
        transparent
        animationType="fade"
        onRequestClose={() => setEditingTask(null)}
      >
        <View style={styles.modalOverlay}>
          <View style={[styles.modalBox, { backgroundColor: theme.surface, borderColor: theme.border }]}>
            <Text style={[styles.modalTitle, { color: theme.text }]}>Edit Task</Text>

            <TextInput
              style={[
                styles.modalInput,
                { backgroundColor: theme.background, borderColor: theme.border, color: theme.text },
              ]}
              placeholder="Task description"
              placeholderTextColor={theme.textMuted}
              value={editText}
              onChangeText={setEditText}
            />

            <Text style={[styles.repeatLabel, { color: theme.textSecondary }]}>Edit Recurrence Schedule:</Text>
            <View style={styles.repeatTabs}>
              <TouchableOpacity
                style={[
                  styles.repeatTab,
                  { backgroundColor: theme.background, borderColor: theme.border },
                  editRepeatMode === 'none' && { backgroundColor: theme.primaryLight, borderColor: theme.primary },
                ]}
                onPress={() => setEditRepeatMode('none')}
              >
                <Text
                  style={[
                    styles.repeatTabText,
                    { color: editRepeatMode === 'none' ? theme.primary : theme.textSecondary },
                  ]}
                >
                  Once (Clear at 12 AM)
                </Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[
                  styles.repeatTab,
                  { backgroundColor: theme.background, borderColor: theme.border },
                  editRepeatMode === 'daily' && { backgroundColor: theme.primaryLight, borderColor: theme.primary },
                ]}
                onPress={() => setEditRepeatMode('daily')}
              >
                <Text
                  style={[
                    styles.repeatTabText,
                    { color: editRepeatMode === 'daily' ? theme.primary : theme.textSecondary },
                  ]}
                >
                  Daily Repeat
                </Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[
                  styles.repeatTab,
                  { backgroundColor: theme.background, borderColor: theme.border },
                  editRepeatMode === 'weekly' && { backgroundColor: theme.primaryLight, borderColor: theme.primary },
                ]}
                onPress={() => setEditRepeatMode('weekly')}
              >
                <Text
                  style={[
                    styles.repeatTabText,
                    { color: editRepeatMode === 'weekly' ? theme.primary : theme.textSecondary },
                  ]}
                >
                  Weekly Repeat
                </Text>
              </TouchableOpacity>
            </View>

            {editRepeatMode === 'weekly' && (
              <View style={styles.weeklyPicker}>
                <Text style={[styles.subLabel, { color: theme.textSecondary }]}>Choose Day to Respawn:</Text>
                <View style={styles.daysRow}>
                  {DAY_NAMES.map((dName, dIdx) => (
                    <TouchableOpacity
                      key={dName}
                      style={[
                        styles.dayCircle,
                        { backgroundColor: theme.background, borderColor: theme.border },
                        editWeeklyDay === dIdx && { backgroundColor: theme.primary, borderColor: theme.primary },
                      ]}
                      onPress={() => setEditWeeklyDay(dIdx)}
                    >
                      <Text
                        style={[
                          styles.dayCircleText,
                          { color: editWeeklyDay === dIdx ? '#FFFFFF' : theme.text },
                        ]}
                      >
                        {dName[0]}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </View>
              </View>
            )}

            <View style={styles.modalButtons}>
              <TouchableOpacity
                style={styles.modalCancelBtn}
                onPress={() => setEditingTask(null)}
              >
                <Text style={[styles.modalCancelText, { color: theme.textSecondary }]}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalConfirmBtn, { backgroundColor: theme.primary }]}
                onPress={handleSaveEdit}
              >
                <Text style={styles.modalConfirmText}>Save Changes</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderBottomWidth: 1,
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
  taskCard: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 12,
    padding: 14,
    marginBottom: 10,
    borderWidth: 1,
  },
  taskCardCompleted: {
    opacity: 0.65,
  },
  checkboxTouch: {
    padding: 4,
    marginRight: 10,
  },
  taskContent: {
    flex: 1,
  },
  taskText: {
    fontSize: 15,
    lineHeight: 22,
  },
  taskTextCompleted: {
    textDecorationLine: 'line-through',
  },
  badgeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 4,
    gap: 8,
  },
  repeatBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 6,
    borderWidth: 1,
  },
  repeatBadgeText: {
    fontSize: 10,
    fontWeight: '600',
  },
  oneOffText: {
    fontSize: 10,
  },
  actionBtns: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  iconBtn: {
    padding: 6,
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
    marginBottom: 16,
  },
  modalInput: {
    borderRadius: 8,
    paddingHorizontal: 14,
    paddingVertical: 12,
    fontSize: 15,
    borderWidth: 1,
    marginBottom: 16,
  },
  repeatLabel: {
    fontSize: 13,
    marginBottom: 8,
    fontWeight: '600',
  },
  repeatTabs: {
    flexDirection: 'column',
    gap: 8,
    marginBottom: 16,
  },
  repeatTab: {
    paddingVertical: 10,
    paddingHorizontal: 14,
    borderRadius: 8,
    borderWidth: 1,
  },
  repeatTabText: {
    fontSize: 13,
    fontWeight: '600',
  },
  weeklyPicker: {
    marginBottom: 16,
  },
  subLabel: {
    fontSize: 12,
    marginBottom: 8,
  },
  daysRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  dayCircle: {
    width: 36,
    height: 36,
    borderRadius: 18,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
  },
  dayCircleText: {
    fontSize: 13,
    fontWeight: '600',
  },
  modalButtons: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: 12,
    marginTop: 8,
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
