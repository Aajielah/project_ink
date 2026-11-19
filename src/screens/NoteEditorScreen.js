// src/screens/NoteEditorScreen.js
import React, { useState, useEffect, useRef } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Alert,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  Modal,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useTheme } from '../theme/ThemeContext';
import { storage } from '../storage/storageManager';
import {
  toggleBold,
  toggleItalic,
  formatBoldTimestamp,
  getCurrentFormattedTime,
  getNextListNumber,
  handleSmartListNewline,
  applyActiveFormatting,
} from '../utils/textStyler';

export default function NoteEditorScreen({ noteId, onBack, onDeleted }) {
  const { theme } = useTheme();
  const [note, setNote] = useState(null);
  const [content, setContent] = useState('');
  const [saveStatus, setSaveStatus] = useState('Saved');
  const [cursorPos, setCursorPos] = useState({ start: 0, end: 0 });
  const [selectionOverride, setSelectionOverride] = useState(null);
  const [isBoldActive, setIsBoldActive] = useState(false);
  const [isItalicActive, setIsItalicActive] = useState(false);
  const [showTimestampModal, setShowTimestampModal] = useState(false);
  const [customTimeInput, setCustomTimeInput] = useState('');
  const [includeBrackets, setIncludeBrackets] = useState(true);
  const saveTimeoutRef = useRef(null);
  const inputRef = useRef(null);
  const contentRef = useRef('');

  useEffect(() => {
    contentRef.current = content;
  }, [content]);

  useEffect(() => {
    loadNote();
    return () => {
      if (saveTimeoutRef.current) clearTimeout(saveTimeoutRef.current);
      if (noteId && contentRef.current !== undefined) {
        storage.updateNote(noteId, contentRef.current);
      }
    };
  }, [noteId]);

  const loadNote = async () => {
    const loaded = await storage.getNoteById(noteId);
    if (loaded) {
      setNote(loaded);
      setContent(loaded.content || '');
    }
  };

  const handleContentChange = (newText, explicitNextCursor = null) => {
    // 1. Check smart list newline continuation first
    const smart = handleSmartListNewline(content, newText, cursorPos);
    let finalContent = smart ? smart.updatedText : newText;
    let nextCursor = explicitNextCursor !== null ? explicitNextCursor : (smart ? smart.newCursor : null);

    // 2. If not a newline and no explicit cursor, check if Bold / Italic mode is active (like MS Word Ctrl+B / Ctrl+I)
    if (!smart && explicitNextCursor === null && (isBoldActive || isItalicActive)) {
      const activeFormat = applyActiveFormatting(content, newText, cursorPos, isBoldActive, isItalicActive);
      if (activeFormat) {
        finalContent = activeFormat.updatedText;
        nextCursor = activeFormat.newCursor;
      }
    }

    setContent(finalContent);
    setSaveStatus('Saving...');

    if (nextCursor !== null) {
      setCursorPos({ start: nextCursor, end: nextCursor });
      setSelectionOverride({ start: nextCursor, end: nextCursor });
    }

    if (saveTimeoutRef.current) clearTimeout(saveTimeoutRef.current);
    saveTimeoutRef.current = setTimeout(async () => {
      await storage.updateNote(noteId, finalContent);
      setSaveStatus('Saved');
    }, 400);
  };

  // ---- REAL BOLD (MS Word Ctrl+B Style) ----
  const handleToggleBold = () => {
    const start = cursorPos.start;
    const end = cursorPos.end;
    if (start !== end) {
      // Text IS highlighted: toggle bold on the selected text
      const selected = content.substring(start, end);
      const converted = toggleBold(selected);
      const updated = content.substring(0, start) + converted + content.substring(end);
      const newCursor = start + converted.length;
      handleContentChange(updated, newCursor);
    } else {
      // NO text highlighted: toggle Bold Mode ON / OFF for next typing (never inserts the word 'bold')
      setIsBoldActive((prev) => !prev);
    }
  };

  // ---- REAL ITALIC (MS Word Ctrl+I Style) ----
  const handleToggleItalic = () => {
    const start = cursorPos.start;
    const end = cursorPos.end;
    if (start !== end) {
      // Text IS highlighted: toggle italic on the selected text
      const selected = content.substring(start, end);
      const converted = toggleItalic(selected);
      const updated = content.substring(0, start) + converted + content.substring(end);
      const newCursor = start + converted.length;
      handleContentChange(updated, newCursor);
    } else {
      // NO text highlighted: toggle Italic Mode ON / OFF for next typing
      setIsItalicActive((prev) => !prev);
    }
  };

  // ---- TIMESTAMP MODAL & INSERT ----
  const openTimestampModal = () => {
    setCustomTimeInput(getCurrentFormattedTime());
    setShowTimestampModal(true);
  };

  const handleInsertTimestamp = (timeToUse = customTimeInput) => {
    const formatted = formatBoldTimestamp(timeToUse || getCurrentFormattedTime(), includeBrackets) + ' ';
    const start = cursorPos.start;
    const end = cursorPos.end;
    const updated = content.substring(0, start) + formatted + content.substring(end);
    const newCursor = start + formatted.length;
    handleContentChange(updated, newCursor);
    setShowTimestampModal(false);
  };

  // ---- SMART NUMBERED LIST (INCREMENTS 1, 2, 3...) ----
  const handleNumberedList = () => {
    const start = cursorPos.start;
    const end = cursorPos.end;
    if (start !== end) {
      const selected = content.substring(start, end);
      const lines = selected.split('\n');
      const baseNum = getNextListNumber(content, start);
      const numberedLines = lines.map((l, idx) => `${baseNum + idx}. ${l}`).join('\n');
      const updated = content.substring(0, start) + numberedLines + content.substring(end);
      const newCursor = start + numberedLines.length;
      handleContentChange(updated, newCursor);
    } else {
      const nextNum = getNextListNumber(content, start);
      const isStartOfLine = start === 0 || content[start - 1] === '\n';
      const prefix = isStartOfLine ? `${nextNum}. ` : `\n${nextNum}. `;
      const updated = content.substring(0, start) + prefix + content.substring(end);
      const newCursor = start + prefix.length;
      handleContentChange(updated, newCursor);
    }
  };

  const insertFormatting = (prefix, suffix = '') => {
    const start = cursorPos.start;
    const end = cursorPos.end;
    const selected = content.substring(start, end);

    let replacement = '';
    if (prefix === '• ' || prefix === '[ ] ' || prefix === '> ') {
      const isStartOfLine = start === 0 || content[start - 1] === '\n';
      replacement = isStartOfLine ? `${prefix}${selected}` : `\n${prefix}${selected}`;
    } else {
      replacement = `${prefix}${selected || 'text'}${suffix}`;
    }

    const updated = content.substring(0, start) + replacement + content.substring(end);
    const newCursor = start + replacement.length;
    handleContentChange(updated, newCursor);
  };

  const handleDelete = () => {
    Alert.alert(
      'Move to Trash',
      'This note will be moved to the Trash for 30 days before being permanently deleted.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Move to Trash',
          style: 'destructive',
          onPress: async () => {
            await storage.deleteNote(noteId);
            if (onDeleted) onDeleted();
            else onBack();
          },
        },
      ]
    );
  };

  if (!note) {
    return (
      <View style={[styles.container, { backgroundColor: theme.background }]}>
        <Text style={[styles.loadingText, { color: theme.textSecondary }]}>Loading note...</Text>
      </View>
    );
  }

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      keyboardVerticalOffset={Platform.OS === 'ios' ? 0 : 0}
      style={[styles.container, { backgroundColor: theme.background }]}
    >
      {/* Top Header */}
      <View style={[styles.header, { backgroundColor: theme.surface, borderBottomColor: theme.border }]}>
        <TouchableOpacity style={styles.iconBtn} onPress={onBack}>
          <Ionicons name="arrow-back" size={24} color={theme.text} />
        </TouchableOpacity>

        <View style={styles.headerCenter}>
          <Text style={[styles.headerTitle, { color: theme.text }]}>{note.title}</Text>
          <Text style={[styles.headerSubtitle, { color: theme.textSecondary }]}>
            {note.dateStr} • {note.timeStr}
          </Text>
        </View>

        <View style={styles.headerRight}>
          <Text style={[styles.statusText, { color: theme.textMuted }]}>{saveStatus}</Text>
          <TouchableOpacity style={styles.iconBtn} onPress={handleDelete}>
            <Ionicons name="trash-outline" size={22} color={theme.danger} />
          </TouchableOpacity>
        </View>
      </View>

      {/* Editor Body */}
      <ScrollView
        style={styles.scrollBody}
        contentContainerStyle={styles.scrollBodyContent}
        keyboardShouldPersistTaps="handled"
      >
        <TextInput
          ref={inputRef}
          style={[styles.textInput, { color: theme.text }]}
          multiline
          placeholder="Start writing your thoughts for today..."
          placeholderTextColor={theme.textMuted}
          value={content}
          selection={selectionOverride || undefined}
          onChangeText={handleContentChange}
          onSelectionChange={(e) => {
            setCursorPos(e.nativeEvent.selection);
            if (selectionOverride) {
              setSelectionOverride(null);
            }
          }}
          textAlignVertical="top"
          autoFocus={!content}
        />
      </ScrollView>

      {/* Rich Formatting Toolbar */}
      <View style={[styles.toolbar, { backgroundColor: theme.surface, borderTopColor: theme.border }]}>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.toolbarScroll}>
          {/* REAL BOLD (MS Word Ctrl+B Style) */}
          <TouchableOpacity
            style={[
              styles.toolBtn,
              { backgroundColor: theme.card, borderColor: theme.border },
              isBoldActive && { backgroundColor: theme.primaryLight, borderColor: theme.primary },
            ]}
            onPress={handleToggleBold}
          >
            <Ionicons name="text" size={18} color={isBoldActive ? theme.primary : theme.text} />
            <Text
              style={[
                styles.toolLabel,
                { color: isBoldActive ? theme.primary : theme.text, fontWeight: '700' },
              ]}
            >
              Bold{isBoldActive ? ' • ON' : ''}
            </Text>
          </TouchableOpacity>

          {/* REAL ITALIC (MS Word Ctrl+I Style) */}
          <TouchableOpacity
            style={[
              styles.toolBtn,
              { backgroundColor: theme.card, borderColor: theme.border },
              isItalicActive && { backgroundColor: theme.primaryLight, borderColor: theme.primary },
            ]}
            onPress={handleToggleItalic}
          >
            <Ionicons name="pencil" size={18} color={isItalicActive ? theme.primary : theme.text} />
            <Text
              style={[
                styles.toolLabel,
                { color: isItalicActive ? theme.primary : theme.text, fontStyle: 'italic' },
              ]}
            >
              Italic{isItalicActive ? ' • ON' : ''}
            </Text>
          </TouchableOpacity>

          {/* TIMESTAMP (BOLD) */}
          <TouchableOpacity
            style={[styles.toolBtn, styles.highlightToolBtn, { backgroundColor: theme.primaryLight, borderColor: theme.primary }]}
            onPress={openTimestampModal}
          >
            <Ionicons name="time" size={18} color={theme.primary} />
            <Text style={[styles.toolLabel, { color: theme.primary, fontWeight: '700' }]}>Timestamp</Text>
          </TouchableOpacity>

          {/* NUMBERED LIST (SMART INCREMENT) */}
          <TouchableOpacity
            style={[styles.toolBtn, { backgroundColor: theme.card, borderColor: theme.border }]}
            onPress={handleNumberedList}
          >
            <Ionicons name="reorder-four" size={18} color={theme.text} />
            <Text style={[styles.toolLabel, { color: theme.text }]}>1. 2. 3.</Text>
          </TouchableOpacity>

          {/* BULLET LIST */}
          <TouchableOpacity
            style={[styles.toolBtn, { backgroundColor: theme.card, borderColor: theme.border }]}
            onPress={() => insertFormatting('• ')}
          >
            <Ionicons name="list" size={18} color={theme.text} />
            <Text style={[styles.toolLabel, { color: theme.text }]}>Bullet</Text>
          </TouchableOpacity>

          {/* TO-DO CHECKLIST */}
          <TouchableOpacity
            style={[styles.toolBtn, { backgroundColor: theme.card, borderColor: theme.border }]}
            onPress={() => insertFormatting('[ ] ')}
          >
            <Ionicons name="checkbox-outline" size={18} color={theme.text} />
            <Text style={[styles.toolLabel, { color: theme.text }]}>To-Do</Text>
          </TouchableOpacity>

          {/* QUOTE */}
          <TouchableOpacity
            style={[styles.toolBtn, { backgroundColor: theme.card, borderColor: theme.border }]}
            onPress={() => insertFormatting('> ')}
          >
            <Ionicons name="chatbox-ellipses-outline" size={18} color={theme.text} />
            <Text style={[styles.toolLabel, { color: theme.text }]}>Quote</Text>
          </TouchableOpacity>
        </ScrollView>
      </View>

      {/* TIMESTAMP CUSTOMIZATION MODAL */}
      <Modal
        visible={showTimestampModal}
        transparent
        animationType="fade"
        onRequestClose={() => setShowTimestampModal(false)}
      >
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          style={styles.modalOverlay}
        >
          <View style={[styles.modalBox, { backgroundColor: theme.surface, borderColor: theme.border }]}>
            <View style={styles.modalHeaderRow}>
              <View style={[styles.modalIconCircle, { backgroundColor: theme.primaryLight }]}>
                <Ionicons name="time" size={22} color={theme.primary} />
              </View>
              <View style={{ flex: 1 }}>
                <Text style={[styles.modalTitle, { color: theme.text }]}>Insert Timestamp</Text>
                <Text style={[styles.modalSubtitle, { color: theme.textSecondary }]}>
                  Customize your time. It will be inserted in bold without any asterisks.
                </Text>
              </View>
            </View>

            {/* Live Bold Preview */}
            <View style={[styles.previewCard, { backgroundColor: theme.background, borderColor: theme.border }]}>
              <Text style={[styles.previewLabel, { color: theme.textMuted }]}>PREVIEW IN NOTE</Text>
              <Text style={[styles.previewText, { color: theme.text }]}>
                {formatBoldTimestamp(customTimeInput || getCurrentFormattedTime(), includeBrackets)}
              </Text>
            </View>

            {/* Time Editable Input */}
            <Text style={[styles.inputLabel, { color: theme.textSecondary }]}>Time to insert:</Text>
            <View style={[styles.timeInputRow, { backgroundColor: theme.background, borderColor: theme.border }]}>
              <TextInput
                style={[styles.timeInput, { color: theme.text }]}
                value={customTimeInput}
                onChangeText={setCustomTimeInput}
                placeholder="00:00 AM"
                placeholderTextColor={theme.textMuted}
              />
              <TouchableOpacity
                style={[styles.nowPill, { backgroundColor: theme.surfaceHover }]}
                onPress={() => setCustomTimeInput(getCurrentFormattedTime())}
              >
                <Ionicons name="refresh" size={14} color={theme.primary} />
                <Text style={[styles.nowPillText, { color: theme.primary }]}>Now</Text>
              </TouchableOpacity>
            </View>

            {/* Options Row */}
            <View style={styles.optionsRow}>
              <TouchableOpacity
                style={[
                  styles.optionPill,
                  { borderColor: theme.border, backgroundColor: includeBrackets ? theme.primaryLight : theme.background },
                  includeBrackets && { borderColor: theme.primary },
                ]}
                onPress={() => setIncludeBrackets(!includeBrackets)}
              >
                <Ionicons
                  name={includeBrackets ? 'checkbox' : 'square-outline'}
                  size={16}
                  color={includeBrackets ? theme.primary : theme.textMuted}
                />
                <Text style={[styles.optionPillText, { color: includeBrackets ? theme.primary : theme.text }]}>
                  Include [Brackets]
                </Text>
              </TouchableOpacity>
            </View>

            {/* Modal Buttons */}
            <View style={styles.modalButtons}>
              <TouchableOpacity
                style={[styles.modalCancelBtn, { borderColor: theme.border }]}
                onPress={() => setShowTimestampModal(false)}
              >
                <Text style={[styles.modalCancelText, { color: theme.textSecondary }]}>Cancel</Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[styles.modalConfirmBtn, { backgroundColor: theme.primary }]}
                onPress={() => handleInsertTimestamp()}
              >
                <Ionicons name="checkmark" size={18} color="#FFFFFF" />
                <Text style={styles.modalConfirmText}>Insert (Bold)</Text>
              </TouchableOpacity>
            </View>
          </View>
        </KeyboardAvoidingView>
      </Modal>
    </KeyboardAvoidingView>
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
    paddingVertical: 12,
    borderBottomWidth: 1,
  },
  headerCenter: {
    flex: 1,
    marginLeft: 12,
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '700',
  },
  headerSubtitle: {
    fontSize: 12,
    marginTop: 2,
  },
  headerRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  statusText: {
    fontSize: 11,
  },
  iconBtn: {
    padding: 6,
    borderRadius: 8,
  },
  scrollBody: {
    flex: 1,
    padding: 16,
  },
  scrollBodyContent: {
    paddingBottom: 160,
  },
  textInput: {
    fontSize: 16,
    lineHeight: 26,
    minHeight: 300,
  },
  toolbar: {
    borderTopWidth: 1,
    paddingVertical: 8,
  },
  toolbarScroll: {
    paddingHorizontal: 12,
    gap: 8,
  },
  toolBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
    gap: 6,
    borderWidth: 1,
  },
  highlightToolBtn: {
    borderWidth: 1.5,
  },
  toolLabel: {
    fontSize: 12,
    fontWeight: '600',
  },
  loadingText: {
    textAlign: 'center',
    marginTop: 40,
    fontSize: 15,
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
  modalHeaderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    marginBottom: 16,
  },
  modalIconCircle: {
    width: 44,
    height: 44,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: '700',
  },
  modalSubtitle: {
    fontSize: 12,
    lineHeight: 16,
    marginTop: 2,
  },
  previewCard: {
    padding: 14,
    borderRadius: 10,
    borderWidth: 1,
    alignItems: 'center',
    marginBottom: 16,
  },
  previewLabel: {
    fontSize: 10,
    fontWeight: '700',
    letterSpacing: 0.8,
    marginBottom: 6,
  },
  previewText: {
    fontSize: 22,
    letterSpacing: 1,
  },
  inputLabel: {
    fontSize: 12,
    fontWeight: '600',
    marginBottom: 6,
  },
  timeInputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 10,
    borderWidth: 1,
    paddingHorizontal: 12,
    marginBottom: 12,
  },
  timeInput: {
    flex: 1,
    fontSize: 16,
    paddingVertical: 10,
    fontWeight: '600',
  },
  nowPill: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 6,
  },
  nowPillText: {
    fontSize: 12,
    fontWeight: '700',
  },
  optionsRow: {
    flexDirection: 'row',
    gap: 10,
    marginBottom: 18,
  },
  optionPill: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
    borderWidth: 1,
  },
  optionPillText: {
    fontSize: 13,
    fontWeight: '600',
  },
  modalButtons: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: 10,
  },
  modalCancelBtn: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 8,
    borderWidth: 1,
  },
  modalCancelText: {
    fontSize: 14,
    fontWeight: '600',
  },
  modalConfirmBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 18,
    paddingVertical: 10,
    borderRadius: 8,
  },
  modalConfirmText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '700',
  },
});
