// src/screens/SettingsScreen.js
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
import { getTrashDaysRemaining } from '../utils/dateUtils';

export default function SettingsScreen() {
  const [currentView, setCurrentView] = useState('menu'); // 'menu' | 'trash'
  const [trashNotes, setTrashNotes] = useState([]);

  // Modals for Export / Import
  const [showExportModal, setShowExportModal] = useState(false);
  const [exportDataString, setExportDataString] = useState('');
  const [copyFeedback, setCopyFeedback] = useState(false);

  const [showImportModal, setShowImportModal] = useState(false);
  const [importInput, setImportInput] = useState('');

  useEffect(() => {
    loadTrash();
  }, []);

  const loadTrash = async () => {
    const list = await storage.purgeExpiredTrash();
    setTrashNotes(list);
  };

  const handleRestore = async (trashNoteId) => {
    await storage.restoreNote(trashNoteId);
    await loadTrash();
    Alert.alert('Restored', 'Note has been restored to its week folder.');
  };

  const handlePermanentDelete = (trashNoteId) => {
    Alert.alert(
      'Delete Forever',
      'This note will be permanently deleted immediately. This cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete Forever',
          style: 'destructive',
          onPress: async () => {
            await storage.permanentlyDeleteNote(trashNoteId);
            await loadTrash();
          },
        },
      ]
    );
  };

  const handleEmptyTrash = () => {
    Alert.alert(
      'Empty Trash',
      'Are you sure you want to permanently delete all notes in the Trash?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Empty Trash',
          style: 'destructive',
          onPress: async () => {
            await storage.emptyTrash();
            await loadTrash();
          },
        },
      ]
    );
  };

  const handleExport = async () => {
    const data = await storage.exportAllData();
    setExportDataString(data);
    setShowExportModal(true);
  };

  const handleImport = async () => {
    if (!importInput.trim()) {
      Alert.alert('Required', 'Please paste the backup JSON data.');
      return;
    }

    const res = await storage.importAllData(importInput.trim());
    if (res.success) {
      setShowImportModal(false);
      setImportInput('');
      await loadTrash();
      Alert.alert('Success', 'Daily Notes data imported successfully!');
    } else {
      Alert.alert('Import Failed', res.error || 'Invalid backup format.');
    }
  };

  // -------------------------------------------------------------
  // TRASH VIEW
  // -------------------------------------------------------------
  if (currentView === 'trash') {
    return (
      <View style={styles.container}>
        <View style={styles.header}>
          <TouchableOpacity
            style={styles.backBtn}
            onPress={() => setCurrentView('menu')}
          >
            <Ionicons name="arrow-back" size={24} color={colors.text} />
          </TouchableOpacity>
          <View style={styles.headerTitles}>
            <Text style={styles.headerTitle}>Trash Bin</Text>
            <Text style={styles.headerSubtitle}>
              Notes stay for 30 days before permanent deletion
            </Text>
          </View>
          {trashNotes.length > 0 && (
            <TouchableOpacity onPress={handleEmptyTrash} style={styles.emptyTrashBtn}>
              <Text style={styles.emptyTrashText}>Empty</Text>
            </TouchableOpacity>
          )}
        </View>

        <FlatList
          data={trashNotes}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.listContainer}
          renderItem={({ item }) => {
            const daysLeft = getTrashDaysRemaining(item.deletedAt);

            return (
              <View style={styles.trashCard}>
                <View style={styles.trashCardHeader}>
                  <Text style={styles.trashTitle}>{item.title}</Text>
                  <View style={styles.daysBadge}>
                    <Ionicons name="time-outline" size={13} color={colors.warning} />
                    <Text style={styles.daysText}>{daysLeft} days left</Text>
                  </View>
                </View>

                <Text style={styles.trashSnippet} numberOfLines={2}>
                  {item.content || '(Empty note)'}
                </Text>

                <View style={styles.trashActions}>
                  <TouchableOpacity
                    style={styles.restoreBtn}
                    onPress={() => handleRestore(item.id)}
                  >
                    <Ionicons name="refresh" size={16} color={colors.secondary} />
                    <Text style={styles.restoreBtnText}>Restore</Text>
                  </TouchableOpacity>

                  <TouchableOpacity
                    style={styles.permDeleteBtn}
                    onPress={() => handlePermanentDelete(item.id)}
                  >
                    <Ionicons name="trash" size={16} color={colors.danger} />
                    <Text style={styles.permDeleteBtnText}>Delete Forever</Text>
                  </TouchableOpacity>
                </View>
              </View>
            );
          }}
          ListEmptyComponent={
            <View style={styles.emptyContainer}>
              <Ionicons name="trash-outline" size={48} color={colors.textMuted} />
              <Text style={styles.emptyTitle}>Trash is empty</Text>
              <Text style={styles.emptySub}>
                Any deleted notes will be kept here safely for 30 days.
              </Text>
            </View>
          }
        />
      </View>
    );
  }

  // -------------------------------------------------------------
  // SETTINGS MAIN MENU
  // -------------------------------------------------------------
  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <View style={styles.headerTitles}>
          <Text style={styles.headerTitle}>Settings</Text>
          <Text style={styles.headerSubtitle}>App management, trash & data</Text>
        </View>
      </View>

      <ScrollView contentContainerStyle={styles.listContainer}>
        {/* Trash Option */}
        <Text style={styles.sectionTitle}>STORAGE & RECOVERY</Text>
        <TouchableOpacity
          style={styles.menuItem}
          onPress={() => {
            loadTrash();
            setCurrentView('trash');
          }}
        >
          <View style={styles.menuIconCircle}>
            <Ionicons name="trash" size={22} color={colors.danger} />
          </View>
          <View style={styles.menuInfo}>
            <Text style={styles.menuTitle}>Trash Bin</Text>
            <Text style={styles.menuSub}>
              {trashNotes.length} notes (auto-purged after 30 days)
            </Text>
          </View>
          <Ionicons name="chevron-forward" size={20} color={colors.textMuted} />
        </TouchableOpacity>

        {/* Data Backup & Restore */}
        <Text style={[styles.sectionTitle, { marginTop: 24 }]}>DATA BACKUP & RESTORE</Text>
        <TouchableOpacity style={styles.menuItem} onPress={handleExport}>
          <View style={styles.menuIconCircle}>
            <Ionicons name="cloud-upload" size={22} color={colors.primary} />
          </View>
          <View style={styles.menuInfo}>
            <Text style={styles.menuTitle}>Export Notes & Tasks</Text>
            <Text style={styles.menuSub}>Backup your projects, notes, and tasks</Text>
          </View>
          <Ionicons name="chevron-forward" size={20} color={colors.textMuted} />
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.menuItem}
          onPress={() => setShowImportModal(true)}
        >
          <View style={styles.menuIconCircle}>
            <Ionicons name="cloud-download" size={22} color={colors.secondary} />
          </View>
          <View style={styles.menuInfo}>
            <Text style={styles.menuTitle}>Import Backup</Text>
            <Text style={styles.menuSub}>Restore from a previous backup file</Text>
          </View>
          <Ionicons name="chevron-forward" size={20} color={colors.textMuted} />
        </TouchableOpacity>

        {/* App Info */}
        <Text style={[styles.sectionTitle, { marginTop: 24 }]}>ABOUT</Text>
        <View style={styles.infoCard}>
          <Text style={styles.infoTitle}>Daily Notes</Text>
          <Text style={styles.infoVersion}>Version 1.0.0</Text>
          <Text style={styles.infoDescription}>
            Organized weekly note-taking with daily auto-generation, midnight task resets, and 30-day trash retention.
          </Text>
        </View>
      </ScrollView>

      {/* Export Modal */}
      <Modal
        visible={showExportModal}
        transparent
        animationType="fade"
        onRequestClose={() => setShowExportModal(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalBox}>
            <Text style={styles.modalTitle}>Backup JSON Data</Text>
            <Text style={styles.modalSubtitle}>
              Copy this backup text to keep a safe copy of all your notes and tasks.
            </Text>

            <TextInput
              style={styles.modalTextArea}
              multiline
              editable={false}
              value={exportDataString}
              selectTextOnFocus
            />

            <View style={styles.modalButtons}>
              <TouchableOpacity
                style={styles.modalCancelBtn}
                onPress={() => setShowExportModal(false)}
              >
                <Text style={styles.modalCancelText}>Close</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      {/* Import Modal */}
      <Modal
        visible={showImportModal}
        transparent
        animationType="fade"
        onRequestClose={() => setShowImportModal(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalBox}>
            <Text style={styles.modalTitle}>Import Backup</Text>
            <Text style={styles.modalSubtitle}>
              Paste your exported JSON data below to restore your notes.
            </Text>

            <TextInput
              style={styles.modalTextArea}
              multiline
              placeholder="Paste JSON backup text here..."
              placeholderTextColor={colors.textMuted}
              value={importInput}
              onChangeText={setImportInput}
              autoFocus
            />

            <View style={styles.modalButtons}>
              <TouchableOpacity
                style={styles.modalCancelBtn}
                onPress={() => {
                  setImportInput('');
                  setShowImportModal(false);
                }}
              >
                <Text style={styles.modalCancelText}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={styles.modalConfirmBtn}
                onPress={handleImport}
              >
                <Text style={styles.modalConfirmText}>Restore</Text>
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
  emptyTrashBtn: {
    backgroundColor: colors.dangerLight,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 8,
  },
  emptyTrashText: {
    color: colors.danger,
    fontSize: 12,
    fontWeight: '700',
  },
  sectionTitle: {
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 1,
    color: colors.textMuted,
    marginBottom: 8,
    marginTop: 8,
  },
  listContainer: {
    padding: 16,
    paddingBottom: 40,
  },
  menuItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.card,
    borderRadius: 12,
    padding: 16,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: colors.border,
  },
  menuIconCircle: {
    width: 44,
    height: 44,
    borderRadius: 10,
    backgroundColor: colors.surface,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 14,
  },
  menuInfo: {
    flex: 1,
  },
  menuTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: colors.text,
  },
  menuSub: {
    fontSize: 12,
    color: colors.textSecondary,
    marginTop: 2,
  },
  infoCard: {
    backgroundColor: colors.surface,
    borderRadius: 12,
    padding: 16,
    borderWidth: 1,
    borderColor: colors.border,
  },
  infoTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.text,
  },
  infoVersion: {
    fontSize: 12,
    color: colors.primary,
    marginTop: 2,
    fontWeight: '600',
  },
  infoDescription: {
    fontSize: 13,
    color: colors.textSecondary,
    lineHeight: 20,
    marginTop: 8,
  },
  trashCard: {
    backgroundColor: colors.card,
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: colors.border,
  },
  trashCardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  trashTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.text,
  },
  daysBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: colors.warningLight,
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
  },
  daysText: {
    color: colors.warning,
    fontSize: 11,
    fontWeight: '600',
  },
  trashSnippet: {
    fontSize: 13,
    color: colors.textSecondary,
    lineHeight: 18,
    marginBottom: 14,
  },
  trashActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: 10,
    borderTopWidth: 1,
    borderTopColor: colors.border,
    paddingTop: 10,
  },
  restoreBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: colors.secondaryLight,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 6,
  },
  restoreBtnText: {
    color: colors.secondary,
    fontSize: 12,
    fontWeight: '600',
  },
  permDeleteBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: colors.dangerLight,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 6,
  },
  permDeleteBtnText: {
    color: colors.danger,
    fontSize: 12,
    fontWeight: '600',
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
    maxHeight: '80%',
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
  modalTextArea: {
    backgroundColor: colors.card,
    borderRadius: 8,
    padding: 12,
    color: colors.text,
    fontSize: 13,
    borderWidth: 1,
    borderColor: colors.border,
    height: 180,
    textAlignVertical: 'top',
    marginBottom: 16,
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
