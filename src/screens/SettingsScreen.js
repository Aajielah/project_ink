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
  Switch,
  BackHandler,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import * as Clipboard from 'expo-clipboard';
import { useTheme } from '../theme/ThemeContext';
import { storage } from '../storage/storageManager';
import { BackupService } from '../services/backupService';
import { getTrashDaysRemaining } from '../utils/dateUtils';

export default function SettingsScreen() {
  const { theme, isDarkMode, toggleTheme } = useTheme();
  const [currentView, setCurrentView] = useState('menu'); // 'menu' | 'trash'
  const [trashNotes, setTrashNotes] = useState([]);

  // Export State
  const [showExportPasswordModal, setShowExportPasswordModal] = useState(false);
  const [exportPassword, setExportPassword] = useState('');
  const [showExportResultModal, setShowExportResultModal] = useState(false);
  const [encryptedExportPayload, setEncryptedExportPayload] = useState('');
  const [copiedFeedback, setCopiedFeedback] = useState(false);

  // Import State
  const [showImportModal, setShowImportModal] = useState(false);
  const [importPayloadInput, setImportPayloadInput] = useState('');
  const [importPasswordInput, setImportPasswordInput] = useState('');

  useEffect(() => {
    loadTrash();
  }, []);

  // ANDROID HARDWARE BACK HANDLER
  useEffect(() => {
    const onBackPress = () => {
      if (showExportResultModal) {
        setShowExportResultModal(false);
        return true;
      }
      if (showExportPasswordModal) {
        setShowExportPasswordModal(false);
        return true;
      }
      if (showImportModal) {
        setShowImportModal(false);
        return true;
      }
      if (currentView === 'trash') {
        setCurrentView('menu');
        return true;
      }
      return false; // Root menu: lets parent tab or Android handle
    };

    const backHandler = BackHandler.addEventListener('hardwareBackPress', onBackPress);
    return () => backHandler.remove();
  }, [currentView, showExportPasswordModal, showExportResultModal, showImportModal]);

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

  // ---- EXPORT (Daily_Counter Style) ----
  const startExport = () => {
    setExportPassword('');
    setShowExportPasswordModal(true);
  };

  const generateEncryptedBackup = async () => {
    if (!exportPassword.trim()) {
      Alert.alert('Required', 'Please enter a password to encrypt your backup.');
      return;
    }

    const payload = await BackupService.exportEncryptedBackup(exportPassword.trim());
    setEncryptedExportPayload(payload);
    setShowExportPasswordModal(false);
    setCopiedFeedback(false);
    setShowExportResultModal(true);
  };

  const copyToClipboard = async () => {
    await Clipboard.setStringAsync(encryptedExportPayload);
    setCopiedFeedback(true);
    Alert.alert('Copied!', 'Encrypted backup payload has been copied to your clipboard.');
  };

  // ---- IMPORT (Daily_Counter Style) ----
  const handleImport = async () => {
    if (!importPayloadInput.trim()) {
      Alert.alert('Required', 'Please paste the encrypted backup payload.');
      return;
    }
    if (!importPasswordInput.trim()) {
      Alert.alert('Required', 'Please enter the decryption password.');
      return;
    }

    const res = await BackupService.importEncryptedBackup(
      importPayloadInput.trim(),
      importPasswordInput.trim()
    );

    if (res.success) {
      setShowImportModal(false);
      setImportPayloadInput('');
      setImportPasswordInput('');
      await loadTrash();
      Alert.alert('Success', 'Backup restored successfully! All notes, tasks, and finances have been recovered.');
    } else {
      Alert.alert('Import Failed', res.error || 'Incorrect password or corrupt backup payload.');
    }
  };

  // -------------------------------------------------------------
  // TRASH VIEW
  // -------------------------------------------------------------
  if (currentView === 'trash') {
    return (
      <View style={[styles.container, { backgroundColor: theme.background }]}>
        <View style={[styles.header, { backgroundColor: theme.surface, borderBottomColor: theme.border }]}>
          <TouchableOpacity
            style={styles.backBtn}
            onPress={() => setCurrentView('menu')}
          >
            <Ionicons name="arrow-back" size={24} color={theme.text} />
          </TouchableOpacity>
          <View style={styles.headerTitles}>
            <Text style={[styles.headerTitle, { color: theme.text }]}>Trash Bin</Text>
            <Text style={[styles.headerSubtitle, { color: theme.textSecondary }]}>
              Notes stay for 30 days before permanent deletion
            </Text>
          </View>
          {trashNotes.length > 0 && (
            <TouchableOpacity
              onPress={handleEmptyTrash}
              style={[styles.emptyTrashBtn, { backgroundColor: theme.dangerLight }]}
            >
              <Text style={[styles.emptyTrashText, { color: theme.danger }]}>Empty</Text>
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
              <View style={[styles.trashCard, { backgroundColor: theme.card, borderColor: theme.border }]}>
                <View style={styles.trashCardHeader}>
                  <Text style={[styles.trashTitle, { color: theme.text }]}>{item.title}</Text>
                  <View style={[styles.daysBadge, { backgroundColor: theme.warningLight }]}>
                    <Ionicons name="time-outline" size={13} color={theme.warning} />
                    <Text style={[styles.daysText, { color: theme.warning }]}>{daysLeft} days left</Text>
                  </View>
                </View>

                <Text style={[styles.trashSnippet, { color: theme.textSecondary }]} numberOfLines={2}>
                  {item.content || '(Empty note)'}
                </Text>

                <View style={[styles.trashActions, { borderTopColor: theme.border }]}>
                  <TouchableOpacity
                    style={[styles.restoreBtn, { backgroundColor: theme.secondaryLight }]}
                    onPress={() => handleRestore(item.id)}
                  >
                    <Ionicons name="refresh" size={16} color={theme.secondary} />
                    <Text style={[styles.restoreBtnText, { color: theme.secondary }]}>Restore</Text>
                  </TouchableOpacity>

                  <TouchableOpacity
                    style={[styles.permDeleteBtn, { backgroundColor: theme.dangerLight }]}
                    onPress={() => handlePermanentDelete(item.id)}
                  >
                    <Ionicons name="trash" size={16} color={theme.danger} />
                    <Text style={[styles.permDeleteBtnText, { color: theme.danger }]}>Delete Forever</Text>
                  </TouchableOpacity>
                </View>
              </View>
            );
          }}
          ListEmptyComponent={
            <View style={styles.emptyContainer}>
              <Ionicons name="trash-outline" size={48} color={theme.textMuted} />
              <Text style={[styles.emptyTitle, { color: theme.text }]}>Trash is empty</Text>
              <Text style={[styles.emptySub, { color: theme.textMuted }]}>
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
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      {/* Header */}
      <View style={[styles.header, { backgroundColor: theme.surface, borderBottomColor: theme.border }]}>
        <View style={styles.headerTitles}>
          <Text style={[styles.headerTitle, { color: theme.text }]}>Settings</Text>
          <Text style={[styles.headerSubtitle, { color: theme.textSecondary }]}>
            App theme, trash & encrypted backup
          </Text>
        </View>
      </View>

      <ScrollView contentContainerStyle={styles.listContainer}>
        {/* APPEARANCE / THEME TOGGLE */}
        <Text style={[styles.sectionTitle, { color: theme.textMuted }]}>APPEARANCE</Text>
        <View style={[styles.menuItem, { backgroundColor: theme.card, borderColor: theme.border }]}>
          <View style={[styles.menuIconCircle, { backgroundColor: theme.surfaceHover }]}>
            <Ionicons
              name={isDarkMode ? 'moon' : 'sunny'}
              size={22}
              color={isDarkMode ? theme.primary : '#F59E0B'}
            />
          </View>
          <View style={styles.menuInfo}>
            <Text style={[styles.menuTitle, { color: theme.text }]}>
              {isDarkMode ? 'Refined Dark Mode' : 'Clean Light Mode'}
            </Text>
            <Text style={[styles.menuSub, { color: theme.textSecondary }]}>
              {isDarkMode ? 'Rich midnight slate aesthetic' : 'Crisp, high-contrast modern light theme'}
            </Text>
          </View>
          <Switch
            value={isDarkMode}
            onValueChange={toggleTheme}
            trackColor={{ false: '#CBD5E1', true: theme.primary }}
            thumbColor="#FFFFFF"
          />
        </View>

        {/* TRASH */}
        <Text style={[styles.sectionTitle, { color: theme.textMuted, marginTop: 20 }]}>STORAGE & RECOVERY</Text>
        <TouchableOpacity
          style={[styles.menuItem, { backgroundColor: theme.card, borderColor: theme.border }]}
          onPress={() => {
            loadTrash();
            setCurrentView('trash');
          }}
        >
          <View style={[styles.menuIconCircle, { backgroundColor: theme.surfaceHover }]}>
            <Ionicons name="trash" size={22} color={theme.danger} />
          </View>
          <View style={styles.menuInfo}>
            <Text style={[styles.menuTitle, { color: theme.text }]}>Trash Bin</Text>
            <Text style={[styles.menuSub, { color: theme.textSecondary }]}>
              {trashNotes.length} notes (auto-purged after 30 days)
            </Text>
          </View>
          <Ionicons name="chevron-forward" size={20} color={theme.textMuted} />
        </TouchableOpacity>

        {/* DATA BACKUP & RESTORE (Daily_Counter Style) */}
        <Text style={[styles.sectionTitle, { color: theme.textMuted, marginTop: 20 }]}>
          DATA BACKUP & RESTORE (ENCRYPTED)
        </Text>
        <TouchableOpacity
          style={[styles.menuItem, { backgroundColor: theme.card, borderColor: theme.border }]}
          onPress={startExport}
        >
          <View style={[styles.menuIconCircle, { backgroundColor: theme.surfaceHover }]}>
            <Ionicons name="lock-closed" size={22} color={theme.primary} />
          </View>
          <View style={styles.menuInfo}>
            <Text style={[styles.menuTitle, { color: theme.text }]}>Export Encrypted Backup</Text>
            <Text style={[styles.menuSub, { color: theme.textSecondary }]}>
              Secured with password & copy to clipboard
            </Text>
          </View>
          <Ionicons name="chevron-forward" size={20} color={theme.textMuted} />
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.menuItem, { backgroundColor: theme.card, borderColor: theme.border }]}
          onPress={() => {
            setImportPayloadInput('');
            setImportPasswordInput('');
            setShowImportModal(true);
          }}
        >
          <View style={[styles.menuIconCircle, { backgroundColor: theme.surfaceHover }]}>
            <Ionicons name="cloud-download" size={22} color={theme.secondary} />
          </View>
          <View style={styles.menuInfo}>
            <Text style={[styles.menuTitle, { color: theme.text }]}>Restore from Backup</Text>
            <Text style={[styles.menuSub, { color: theme.textSecondary }]}>
              Paste payload & decrypt with password
            </Text>
          </View>
          <Ionicons name="chevron-forward" size={20} color={theme.textMuted} />
        </TouchableOpacity>

        {/* 1-TAP INSTANT RECOVERY */}
        <TouchableOpacity
          style={[styles.menuItem, { backgroundColor: theme.card, borderColor: theme.border }]}
          onPress={async () => {
            Alert.alert(
              'Restore Recovered Data?',
              'This will instantly restore your 2026 project, October folder, and Chapter 40 note with zero passwords.',
              [
                { text: 'Cancel', style: 'cancel' },
                {
                  text: 'Restore Now',
                  onPress: async () => {
                    const { restoreRecoveredChapterData } = require('../services/recoveryData');
                    await restoreRecoveredChapterData();
                    Alert.alert('Restored!', '2026 Project, October folder, and Chapter 40 have been restored successfully!');
                  },
                },
              ]
            );
          }}
        >
          <View style={[styles.menuIconCircle, { backgroundColor: theme.surfaceHover }]}>
            <Ionicons name="flash" size={22} color="#10B981" />
          </View>
          <View style={styles.menuInfo}>
            <Text style={[styles.menuTitle, { color: theme.text }]}>1-Tap Recover Chapter 40</Text>
            <Text style={[styles.menuSub, { color: theme.textSecondary }]}>
              Instantly restore 2026 & Chapter 40 without password
            </Text>
          </View>
          <Ionicons name="checkmark-circle" size={20} color="#10B981" />
        </TouchableOpacity>

        {/* ABOUT */}
        <Text style={[styles.sectionTitle, { color: theme.textMuted, marginTop: 20 }]}>ABOUT</Text>
        <View style={[styles.infoCard, { backgroundColor: theme.card, borderColor: theme.border }]}>
          <Text style={[styles.infoTitle, { color: theme.text }]}>Daily Notes & Finances</Text>
          <Text style={[styles.infoVersion, { color: theme.primary }]}>Version 1.1.0</Text>
          <Text style={[styles.infoDescription, { color: theme.textSecondary }]}>
            Organized weekly notes, recurring tasks with midnight reset, daily financial ledgers with balance rollover, and encrypted backups.
          </Text>
        </View>
      </ScrollView>

      {/* EXPORT STEP 1: PASSWORD MODAL */}
      <Modal
        visible={showExportPasswordModal}
        transparent
        animationType="fade"
        onRequestClose={() => setShowExportPasswordModal(false)}
      >
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          style={styles.modalOverlay}
        >
          <View style={[styles.modalBox, { backgroundColor: theme.surface, borderColor: theme.border }]}>
            <Text style={[styles.modalTitle, { color: theme.text }]}>Export Encrypted Backup</Text>
            <Text style={[styles.modalSubtitle, { color: theme.textSecondary }]}>
              Enter a password to encrypt your entire database. You will need this password to restore your data.
            </Text>

            <TextInput
              style={[
                styles.modalInput,
                { backgroundColor: theme.background, borderColor: theme.border, color: theme.text },
              ]}
              placeholder="Encryption Password"
              placeholderTextColor={theme.textMuted}
              secureTextEntry
              value={exportPassword}
              onChangeText={setExportPassword}
              autoFocus
            />

            <View style={styles.modalButtons}>
              <TouchableOpacity
                style={styles.modalCancelBtn}
                onPress={() => setShowExportPasswordModal(false)}
              >
                <Text style={[styles.modalCancelText, { color: theme.textSecondary }]}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalConfirmBtn, { backgroundColor: theme.primary }]}
                onPress={generateEncryptedBackup}
              >
                <Text style={styles.modalConfirmText}>Generate Backup</Text>
              </TouchableOpacity>
            </View>
          </View>
        </KeyboardAvoidingView>
      </Modal>

      {/* EXPORT STEP 2: RESULT & COPY TO CLIPBOARD MODAL */}
      <Modal
        visible={showExportResultModal}
        transparent
        animationType="fade"
        onRequestClose={() => setShowExportResultModal(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={[styles.modalBox, { backgroundColor: theme.surface, borderColor: theme.border }]}>
            <Text style={[styles.modalTitle, { color: theme.text }]}>Encrypted Backup Ready</Text>
            <Text style={[styles.modalSubtitle, { color: theme.textSecondary }]}>
              Your database is secured with password encryption. Copy and save your backup payload:
            </Text>

            <View style={[styles.payloadContainer, { backgroundColor: theme.background, borderColor: theme.border }]}>
              <Text style={[styles.payloadPreview, { color: theme.textSecondary }]}>
                {encryptedExportPayload.length > 100
                  ? `${encryptedExportPayload.substring(0, 100)}... (${encryptedExportPayload.length} chars)`
                  : encryptedExportPayload}
              </Text>
            </View>

            <TouchableOpacity
              style={[styles.copyBtn, { backgroundColor: theme.primary }]}
              onPress={copyToClipboard}
            >
              <Ionicons name="copy-outline" size={18} color="#FFFFFF" />
              <Text style={styles.copyBtnText}>
                {copiedFeedback ? 'Copied to Clipboard!' : 'Copy to Clipboard'}
              </Text>
            </TouchableOpacity>

            <View style={[styles.modalButtons, { marginTop: 14 }]}>
              <TouchableOpacity
                style={styles.modalCancelBtn}
                onPress={() => setShowExportResultModal(false)}
              >
                <Text style={[styles.modalCancelText, { color: theme.textSecondary }]}>Done</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      {/* IMPORT MODAL (Daily_Counter Style) */}
      <Modal
        visible={showImportModal}
        transparent
        animationType="fade"
        onRequestClose={() => setShowImportModal(false)}
      >
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          style={styles.modalOverlay}
        >
          <View style={[styles.modalBox, { backgroundColor: theme.surface, borderColor: theme.border, maxHeight: '85%' }]}>
            <ScrollView showsVerticalScrollIndicator={false} keyboardShouldPersistTaps="handled">
              <Text style={[styles.modalTitle, { color: theme.text }]}>Restore from Backup</Text>
              <Text style={[styles.modalSubtitle, { color: theme.textSecondary }]}>
                Paste your encrypted backup payload and enter the password to decrypt:
              </Text>

              <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 }}>
                <Text style={{ fontSize: 12, fontWeight: '600', color: theme.textSecondary }}>
                  Payload Data:
                </Text>
                <TouchableOpacity
                  style={{
                    flexDirection: 'row',
                    alignItems: 'center',
                    gap: 4,
                    paddingHorizontal: 10,
                    paddingVertical: 5,
                    backgroundColor: theme.card,
                    borderRadius: 6,
                    borderWidth: 1,
                    borderColor: theme.border,
                  }}
                  onPress={async () => {
                    const str = await Clipboard.getStringAsync();
                    if (str && str.trim()) {
                      setImportPayloadInput(str.trim());
                      Alert.alert('Pasted!', `Loaded ${str.trim().length} characters from clipboard.`);
                    } else {
                      Alert.alert('Clipboard Empty', 'Your clipboard does not have any text copied.');
                    }
                  }}
                >
                  <Ionicons name="clipboard-outline" size={14} color={theme.primary} />
                  <Text style={{ fontSize: 12, fontWeight: '700', color: theme.primary }}>Paste from Clipboard</Text>
                </TouchableOpacity>
              </View>

              <TextInput
                style={[
                  styles.modalTextArea,
                  { backgroundColor: theme.background, borderColor: theme.border, color: theme.text },
                ]}
                multiline
                placeholder="Paste encrypted base64 payload here..."
                placeholderTextColor={theme.textMuted}
                value={importPayloadInput}
                onChangeText={setImportPayloadInput}
              />

              <TextInput
                style={[
                  styles.modalInput,
                  { backgroundColor: theme.background, borderColor: theme.border, color: theme.text, marginTop: 10 },
                ]}
                placeholder="Decryption Password"
                placeholderTextColor={theme.textMuted}
                secureTextEntry
                value={importPasswordInput}
                onChangeText={setImportPasswordInput}
              />

              <View style={styles.modalButtons}>
                <TouchableOpacity
                  style={styles.modalCancelBtn}
                  onPress={() => setShowImportModal(false)}
                >
                  <Text style={[styles.modalCancelText, { color: theme.textSecondary }]}>Cancel</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={[styles.modalConfirmBtn, { backgroundColor: theme.secondary }]}
                  onPress={handleImport}
                >
                  <Text style={styles.modalConfirmText}>Decrypt & Restore</Text>
                </TouchableOpacity>
              </View>
            </ScrollView>
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
  emptyTrashBtn: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 8,
  },
  emptyTrashText: {
    fontSize: 12,
    fontWeight: '700',
  },
  sectionTitle: {
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 1,
    marginBottom: 8,
  },
  listContainer: {
    padding: 16,
    paddingBottom: 40,
  },
  menuItem: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 12,
    padding: 16,
    marginBottom: 10,
    borderWidth: 1,
  },
  menuIconCircle: {
    width: 44,
    height: 44,
    borderRadius: 10,
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
  },
  menuSub: {
    fontSize: 12,
    marginTop: 2,
  },
  infoCard: {
    borderRadius: 12,
    padding: 16,
    borderWidth: 1,
  },
  infoTitle: {
    fontSize: 16,
    fontWeight: '700',
  },
  infoVersion: {
    fontSize: 12,
    marginTop: 2,
    fontWeight: '600',
  },
  infoDescription: {
    fontSize: 13,
    lineHeight: 20,
    marginTop: 8,
  },
  trashCard: {
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    borderWidth: 1,
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
  },
  daysBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
  },
  daysText: {
    fontSize: 11,
    fontWeight: '600',
  },
  trashSnippet: {
    fontSize: 13,
    lineHeight: 18,
    marginBottom: 14,
  },
  trashActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: 10,
    borderTopWidth: 1,
    paddingTop: 10,
  },
  restoreBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 6,
  },
  restoreBtnText: {
    fontSize: 12,
    fontWeight: '600',
  },
  permDeleteBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 6,
  },
  permDeleteBtnText: {
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
    marginTop: 12,
  },
  emptySub: {
    fontSize: 13,
    textAlign: 'center',
    marginTop: 6,
    paddingHorizontal: 30,
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
    maxHeight: '85%',
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
    fontSize: 14,
    borderWidth: 1,
    marginBottom: 16,
  },
  modalTextArea: {
    borderRadius: 8,
    padding: 12,
    fontSize: 12,
    borderWidth: 1,
    height: 120,
    textAlignVertical: 'top',
  },
  payloadContainer: {
    borderRadius: 8,
    padding: 10,
    borderWidth: 1,
    marginBottom: 14,
  },
  payloadPreview: {
    fontSize: 11,
    fontFamily: Platform.OS === 'ios' ? 'Courier' : 'monospace',
  },
  copyBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 12,
    borderRadius: 8,
    gap: 8,
  },
  copyBtnText: {
    color: '#FFFFFF',
    fontWeight: '700',
    fontSize: 14,
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
