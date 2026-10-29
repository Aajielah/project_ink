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
  ScrollView,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors } from '../theme/colors';
import { storage } from '../storage/storageManager';
import { MONTH_NAMES, isWeekActive, isWeekExpired } from '../utils/dateUtils';
import WeekNotesScreen from './WeekNotesScreen';
import NoteEditorScreen from './NoteEditorScreen';

export default function HomeScreen() {
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

  const [showMonthModal, setShowMonthModal] = useState(false);
  const [selectedMonthIndex, setSelectedMonthIndex] = useState(new Date().getMonth());

  useEffect(() => {
    loadProjects();
    // Daily background checks
    storage.ensureDailyNotesGenerated();
    storage.purgeExpiredTrash();
    storage.runMidnightTaskReset();
  }, []);

  const loadProjects = async () => {
    const list = await storage.getProjects();
    setProjects(list);
  };

  const loadMonths = async (proj) => {
    const list = await storage.getMonthFolders(proj.id);
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
    // Use year from name if numeric (e.g., "2026"), else current year
    const extractedYear = parseInt(name, 10) || new Date().getFullYear();
    const created = await storage.createProject(name, extractedYear);
    setProjectNameInput('');
    setShowProjectModal(false);
    await loadProjects();
    // Immediately open the newly created project
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

  // ---- MONTH CREATION ----
  const handleCreateMonth = async () => {
    if (!selectedProject) return;

    const result = await storage.createMonthFolder(
      selectedProject.id,
      selectedProject.year,
      selectedMonthIndex
    );

    setShowMonthModal(false);

    if (result.alreadyExisted) {
      Alert.alert('Notice', `${result.month.monthName} folder already exists for this project.`);
    }

    await loadMonths(selectedProject);
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
      <View style={styles.container}>
        <View style={styles.header}>
          <TouchableOpacity
            style={styles.backBtn}
            onPress={() => setCurrentLevel('months')}
          >
            <Ionicons name="arrow-back" size={24} color={colors.text} />
          </TouchableOpacity>
          <View style={styles.headerTitles}>
            <Text style={styles.headerTitle}>{selectedMonth?.monthName}</Text>
            <Text style={styles.headerSubtitle}>
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
                style={[styles.card, active && styles.activeCard]}
                activeOpacity={0.7}
                onPress={() => openWeek(item)}
              >
                <View style={styles.cardHeader}>
                  <View style={styles.iconCircle}>
                    <Ionicons
                      name="folder"
                      size={24}
                      color={active ? colors.secondary : colors.primary}
                    />
                  </View>
                  <View style={styles.cardMainInfo}>
                    <Text style={styles.cardTitle}>{item.label}</Text>
                    <Text style={styles.cardSubtitle}>{item.dateRange}</Text>
                  </View>
                  {active ? (
                    <View style={styles.badgeActive}>
                      <Text style={styles.badgeActiveText}>Active</Text>
                    </View>
                  ) : expired ? (
                    <View style={styles.badgeExpired}>
                      <Text style={styles.badgeExpiredText}>Ended</Text>
                    </View>
                  ) : null}
                  <Ionicons name="chevron-forward" size={20} color={colors.textMuted} />
                </View>
              </TouchableOpacity>
            );
          }}
          ListEmptyComponent={
            <View style={styles.emptyContainer}>
              <Ionicons name="calendar-outline" size={48} color={colors.textMuted} />
              <Text style={styles.emptyTitle}>No remaining weeks in this month</Text>
            </View>
          }
        />
      </View>
    );
  }

  // -------------------------------------------------------------
  // RENDER LEVEL: Months inside a Project
  // -------------------------------------------------------------
  if (currentLevel === 'months') {
    return (
      <View style={styles.container}>
        <View style={styles.header}>
          <TouchableOpacity
            style={styles.backBtn}
            onPress={() => setCurrentLevel('projects')}
          >
            <Ionicons name="arrow-back" size={24} color={colors.text} />
          </TouchableOpacity>
          <View style={styles.headerTitles}>
            <Text style={styles.headerTitle}>{selectedProject?.name}</Text>
            <Text style={styles.headerSubtitle}>
              Year {selectedProject?.year} • Months
            </Text>
          </View>
        </View>

        <FlatList
          data={monthFolders}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.listContainer}
          renderItem={({ item }) => (
            <TouchableOpacity
              style={styles.card}
              activeOpacity={0.7}
              onPress={() => openMonth(item)}
            >
              <View style={styles.cardHeader}>
                <View style={styles.iconCircle}>
                  <Ionicons name="calendar" size={24} color={colors.primary} />
                </View>
                <View style={styles.cardMainInfo}>
                  <Text style={styles.cardTitle}>{item.monthName}</Text>
                  <Text style={styles.cardSubtitle}>Tap to view weeks</Text>
                </View>
                <Ionicons name="chevron-forward" size={20} color={colors.textMuted} />
              </View>
            </TouchableOpacity>
          )}
          ListEmptyComponent={
            <View style={styles.emptyContainer}>
              <Ionicons name="calendar-outline" size={48} color={colors.textMuted} />
              <Text style={styles.emptyTitle}>No month folders yet</Text>
              <Text style={styles.emptySub}>
                Tap the big + button below to pick a month and generate weeks.
              </Text>
            </View>
          }
        />

        {/* Big Plus Button for Months */}
        <TouchableOpacity
          style={styles.fab}
          activeOpacity={0.8}
          onPress={() => setShowMonthModal(true)}
        >
          <Ionicons name="add" size={32} color={colors.white} />
        </TouchableOpacity>

        {/* Pick Month Modal */}
        <Modal
          visible={showMonthModal}
          transparent
          animationType="fade"
          onRequestClose={() => setShowMonthModal(false)}
        >
          <View style={styles.modalOverlay}>
            <View style={styles.modalBox}>
              <Text style={styles.modalTitle}>Select Month</Text>
              <Text style={styles.modalSubtitle}>
                Week folders will automatically be generated for this month.
              </Text>

              <ScrollView style={styles.monthScroll} showsVerticalScrollIndicator={false}>
                {MONTH_NAMES.map((mName, idx) => (
                  <TouchableOpacity
                    key={mName}
                    style={[
                      styles.monthOption,
                      selectedMonthIndex === idx && styles.monthOptionSelected,
                    ]}
                    onPress={() => setSelectedMonthIndex(idx)}
                  >
                    <Text
                      style={[
                        styles.monthOptionText,
                        selectedMonthIndex === idx && styles.monthOptionTextSelected,
                      ]}
                    >
                      {mName}
                    </Text>
                    {selectedMonthIndex === idx && (
                      <Ionicons name="checkmark-circle" size={20} color={colors.primary} />
                    )}
                  </TouchableOpacity>
                ))}
              </ScrollView>

              <View style={styles.modalButtons}>
                <TouchableOpacity
                  style={styles.modalCancelBtn}
                  onPress={() => setShowMonthModal(false)}
                >
                  <Text style={styles.modalCancelText}>Cancel</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={styles.modalConfirmBtn}
                  onPress={handleCreateMonth}
                >
                  <Text style={styles.modalConfirmText}>Create</Text>
                </TouchableOpacity>
              </View>
            </View>
          </View>
        </Modal>
      </View>
    );
  }

  // -------------------------------------------------------------
  // RENDER LEVEL: Projects (Main Home View)
  // -------------------------------------------------------------
  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <View style={styles.headerTitles}>
          <Text style={styles.headerTitle}>Daily Notes</Text>
          <Text style={styles.headerSubtitle}>Projects</Text>
        </View>
      </View>

      <FlatList
        data={projects}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.listContainer}
        renderItem={({ item }) => (
          <TouchableOpacity
            style={styles.card}
            activeOpacity={0.7}
            onPress={() => openProject(item)}
          >
            <View style={styles.cardHeader}>
              <View style={styles.iconCircle}>
                <Ionicons name="folder-open" size={24} color={colors.primary} />
              </View>
              <View style={styles.cardMainInfo}>
                <Text style={styles.cardTitle}>{item.name}</Text>
                <Text style={styles.cardSubtitle}>Year {item.year}</Text>
              </View>
              <TouchableOpacity
                style={styles.cardDeleteBtn}
                onPress={(e) => handleDeleteProject(item.id, e)}
              >
                <Ionicons name="trash-outline" size={18} color={colors.textMuted} />
              </TouchableOpacity>
              <Ionicons name="chevron-forward" size={20} color={colors.textMuted} />
            </View>
          </TouchableOpacity>
        )}
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Ionicons name="folder-outline" size={48} color={colors.textMuted} />
            <Text style={styles.emptyTitle}>No projects created yet</Text>
            <Text style={styles.emptySub}>
              Tap the big + button below and name your project (e.g. 2026).
            </Text>
          </View>
        }
      />

      {/* Big Plus Button for Projects */}
      <TouchableOpacity
        style={styles.fab}
        activeOpacity={0.8}
        onPress={() => setShowProjectModal(true)}
      >
        <Ionicons name="add" size={32} color={colors.white} />
      </TouchableOpacity>

      {/* Create Project Modal */}
      <Modal
        visible={showProjectModal}
        transparent
        animationType="fade"
        onRequestClose={() => setShowProjectModal(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalBox}>
            <Text style={styles.modalTitle}>New Project</Text>
            <Text style={styles.modalSubtitle}>Enter your project name to get started.</Text>

            <TextInput
              style={styles.modalInput}
              placeholder="e.g. 2026"
              placeholderTextColor={colors.textMuted}
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
                <Text style={styles.modalCancelText}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={styles.modalConfirmBtn}
                onPress={handleCreateProject}
              >
                <Text style={styles.modalConfirmText}>Create</Text>
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
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
    backgroundColor: colors.surface,
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
  card: {
    backgroundColor: colors.card,
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: colors.border,
  },
  activeCard: {
    borderColor: colors.secondary,
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  iconCircle: {
    width: 44,
    height: 44,
    borderRadius: 10,
    backgroundColor: colors.surface,
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
    color: colors.text,
  },
  cardSubtitle: {
    fontSize: 12,
    color: colors.textSecondary,
    marginTop: 2,
  },
  cardDeleteBtn: {
    padding: 8,
    marginRight: 4,
  },
  badgeActive: {
    backgroundColor: colors.secondaryLight,
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 8,
    marginRight: 8,
  },
  badgeActiveText: {
    color: colors.secondary,
    fontSize: 11,
    fontWeight: '600',
  },
  badgeExpired: {
    backgroundColor: colors.surface,
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 8,
    marginRight: 8,
  },
  badgeExpiredText: {
    color: colors.textMuted,
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
  },
  modalSubtitle: {
    fontSize: 13,
    color: colors.textSecondary,
    marginTop: 4,
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
    marginBottom: 20,
  },
  monthScroll: {
    maxHeight: 250,
    marginBottom: 16,
  },
  monthOption: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 12,
    paddingHorizontal: 14,
    borderRadius: 8,
    marginBottom: 6,
    backgroundColor: colors.card,
  },
  monthOptionSelected: {
    backgroundColor: colors.primaryLight,
    borderWidth: 1,
    borderColor: colors.primary,
  },
  monthOptionText: {
    fontSize: 15,
    color: colors.text,
  },
  monthOptionTextSelected: {
    color: colors.primary,
    fontWeight: '700',
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
