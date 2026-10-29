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
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors } from '../theme/colors';
import { storage } from '../storage/storageManager';
import { DAY_NAMES } from '../utils/dateUtils';

export default function TasksScreen() {
  const [tasks, setTasks] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [taskText, setTaskText] = useState('');
  const [repeatMode, setRepeatMode] = useState('none'); // 'none' | 'daily' | 'weekly'
  const [weeklyDay, setWeeklyDay] = useState(1); // 1 = Monday

  useEffect(() => {
    loadTasks();
    // Midnight reset check
    storage.runMidnightTaskReset().then(() => loadTasks());
  }, []);

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
      <View style={[styles.taskCard, isCompleted && styles.taskCardCompleted]}>
        <TouchableOpacity
          style={styles.checkboxTouch}
          onPress={() => handleToggle(item.id)}
        >
          <Ionicons
            name={isCompleted ? 'checkbox' : 'square-outline'}
            size={24}
            color={isCompleted ? colors.secondary : colors.textSecondary}
          />
        </TouchableOpacity>

        <View style={styles.taskContent}>
          <Text
            style={[
              styles.taskText,
              isCompleted && styles.taskTextCompleted,
            ]}
          >
            {item.text}
          </Text>

          {/* Repeat badges */}
          <View style={styles.badgeRow}>
            {item.repeat === 'daily' && (
              <View style={styles.repeatBadge}>
                <Ionicons name="repeat" size={12} color={colors.primary} />
                <Text style={styles.repeatBadgeText}>Daily Repeat</Text>
              </View>
            )}
            {item.repeat === 'weekly' && (
              <View style={styles.repeatBadge}>
                <Ionicons name="calendar-outline" size={12} color={colors.warning} />
                <Text style={styles.repeatBadgeText}>
                  Weekly ({DAY_NAMES[item.weeklyDay]?.slice(0, 3)})
                </Text>
              </View>
            )}
            {item.repeat === 'none' && (
              <Text style={styles.oneOffText}>Clears at 12 AM</Text>
            )}
          </View>
        </View>

        <TouchableOpacity
          style={styles.deleteBtn}
          onPress={() => handleDelete(item.id)}
        >
          <Ionicons name="close-circle-outline" size={20} color={colors.textMuted} />
        </TouchableOpacity>
      </View>
    );
  };

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <View style={styles.headerTitles}>
          <Text style={styles.headerTitle}>Tasks</Text>
          <Text style={styles.headerSubtitle}>
            Completed tasks clear automatically at 12:00 AM midnight
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
            <Ionicons name="checkbox-outline" size={48} color={colors.textMuted} />
            <Text style={styles.emptyTitle}>No tasks yet</Text>
            <Text style={styles.emptySub}>
              Tap the big + button below to add your daily or recurring tasks.
            </Text>
          </View>
        }
      />

      {/* Floating Plus Button */}
      <TouchableOpacity
        style={styles.fab}
        activeOpacity={0.8}
        onPress={() => setShowModal(true)}
      >
        <Ionicons name="add" size={32} color={colors.white} />
      </TouchableOpacity>

      {/* Create Task Modal */}
      <Modal
        visible={showModal}
        transparent
        animationType="fade"
        onRequestClose={() => setShowModal(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalBox}>
            <Text style={styles.modalTitle}>New Task</Text>

            <TextInput
              style={styles.modalInput}
              placeholder="What do you need to do?"
              placeholderTextColor={colors.textMuted}
              value={taskText}
              onChangeText={setTaskText}
              autoFocus
            />

            <Text style={styles.repeatLabel}>Repeat Schedule:</Text>
            <View style={styles.repeatTabs}>
              <TouchableOpacity
                style={[
                  styles.repeatTab,
                  repeatMode === 'none' && styles.repeatTabSelected,
                ]}
                onPress={() => setRepeatMode('none')}
              >
                <Text
                  style={[
                    styles.repeatTabText,
                    repeatMode === 'none' && styles.repeatTabTextSelected,
                  ]}
                >
                  Once (Clear at 12 AM)
                </Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[
                  styles.repeatTab,
                  repeatMode === 'daily' && styles.repeatTabSelected,
                ]}
                onPress={() => setRepeatMode('daily')}
              >
                <Text
                  style={[
                    styles.repeatTabText,
                    repeatMode === 'daily' && styles.repeatTabTextSelected,
                  ]}
                >
                  Daily Repeat
                </Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[
                  styles.repeatTab,
                  repeatMode === 'weekly' && styles.repeatTabSelected,
                ]}
                onPress={() => setRepeatMode('weekly')}
              >
                <Text
                  style={[
                    styles.repeatTabText,
                    repeatMode === 'weekly' && styles.repeatTabTextSelected,
                  ]}
                >
                  Weekly Repeat
                </Text>
              </TouchableOpacity>
            </View>

            {/* Weekly Day Picker if Weekly Repeat */}
            {repeatMode === 'weekly' && (
              <View style={styles.weeklyPicker}>
                <Text style={styles.subLabel}>Choose Day to Respawn:</Text>
                <View style={styles.daysRow}>
                  {DAY_NAMES.map((dName, dIdx) => (
                    <TouchableOpacity
                      key={dName}
                      style={[
                        styles.dayCircle,
                        weeklyDay === dIdx && styles.dayCircleSelected,
                      ]}
                      onPress={() => setWeeklyDay(dIdx)}
                    >
                      <Text
                        style={[
                          styles.dayCircleText,
                          weeklyDay === dIdx && styles.dayCircleTextSelected,
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
                <Text style={styles.modalCancelText}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={styles.modalConfirmBtn}
                onPress={handleCreateTask}
              >
                <Text style={styles.modalConfirmText}>Add Task</Text>
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
    backgroundColor: colors.background,
  },
  header: {
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
    backgroundColor: colors.surface,
  },
  headerTitles: {
    flex: 1,
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: colors.text,
  },
  headerSubtitle: {
    fontSize: 12,
    color: colors.textSecondary,
    marginTop: 2,
  },
  listContainer: {
    padding: 16,
    paddingBottom: 90,
  },
  taskCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.card,
    borderRadius: 12,
    padding: 14,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: colors.border,
  },
  taskCardCompleted: {
    opacity: 0.65,
    backgroundColor: colors.surface,
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
    color: colors.text,
    lineHeight: 22,
  },
  taskTextCompleted: {
    textDecorationLine: 'line-through',
    color: colors.textMuted,
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
    backgroundColor: colors.surface,
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: colors.border,
  },
  repeatBadgeText: {
    fontSize: 10,
    color: colors.textSecondary,
    fontWeight: '600',
  },
  oneOffText: {
    fontSize: 10,
    color: colors.textMuted,
  },
  deleteBtn: {
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
    color: colors.text,
    marginTop: 12,
  },
  emptySub: {
    fontSize: 13,
    color: colors.textMuted,
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
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
    elevation: 6,
    shadowColor: '#000',
    shadowOpacity: 0.3,
    shadowRadius: 5,
    shadowOffset: { width: 0, height: 3 },
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.7)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
  modalBox: {
    width: '100%',
    backgroundColor: colors.surface,
    borderRadius: 16,
    padding: 20,
    borderWidth: 1,
    borderColor: colors.border,
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: colors.text,
    marginBottom: 16,
  },
  modalInput: {
    backgroundColor: colors.card,
    borderRadius: 8,
    paddingHorizontal: 14,
    paddingVertical: 12,
    color: colors.text,
    fontSize: 15,
    borderWidth: 1,
    borderColor: colors.border,
    marginBottom: 16,
  },
  repeatLabel: {
    fontSize: 13,
    color: colors.textSecondary,
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
    backgroundColor: colors.card,
    borderWidth: 1,
    borderColor: colors.border,
  },
  repeatTabSelected: {
    backgroundColor: colors.primaryLight,
    borderColor: colors.primary,
  },
  repeatTabText: {
    fontSize: 13,
    color: colors.textSecondary,
    fontWeight: '600',
  },
  repeatTabTextSelected: {
    color: colors.primary,
    fontWeight: '700',
  },
  weeklyPicker: {
    marginBottom: 16,
  },
  subLabel: {
    fontSize: 12,
    color: colors.textSecondary,
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
    backgroundColor: colors.card,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: colors.border,
  },
  dayCircleSelected: {
    backgroundColor: colors.primary,
    borderColor: colors.primary,
  },
  dayCircleText: {
    fontSize: 13,
    color: colors.text,
    fontWeight: '600',
  },
  dayCircleTextSelected: {
    color: colors.white,
    fontWeight: '700',
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
    color: colors.textSecondary,
    fontWeight: '600',
  },
  modalConfirmBtn: {
    backgroundColor: colors.primary,
    paddingVertical: 10,
    paddingHorizontal: 20,
    borderRadius: 8,
  },
  modalConfirmText: {
    color: colors.white,
    fontWeight: '700',
  },
});
