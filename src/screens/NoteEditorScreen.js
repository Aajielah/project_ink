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
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors } from '../theme/colors';
import { storage } from '../storage/storageManager';

export default function NoteEditorScreen({ noteId, onBack, onDeleted }) {
  const [note, setNote] = useState(null);
  const [content, setContent] = useState('');
  const [saveStatus, setSaveStatus] = useState('Saved');
  const [cursorPos, setCursorPos] = useState({ start: 0, end: 0 });
  const saveTimeoutRef = useRef(null);
  const inputRef = useRef(null);

  useEffect(() => {
    loadNote();
    return () => {
      if (saveTimeoutRef.current) clearTimeout(saveTimeoutRef.current);
    };
  }, [noteId]);

  const loadNote = async () => {
    const loaded = await storage.getNoteById(noteId);
    if (loaded) {
      setNote(loaded);
      setContent(loaded.content || '');
    }
  };

  const handleContentChange = (newText) => {
    setContent(newText);
    setSaveStatus('Saving...');

    if (saveTimeoutRef.current) clearTimeout(saveTimeoutRef.current);
    saveTimeoutRef.current = setTimeout(async () => {
      await storage.updateNote(noteId, newText);
      setSaveStatus('Saved');
    }, 400);
  };

  const insertFormatting = (prefix, suffix = '') => {
    const start = cursorPos.start;
    const end = cursorPos.end;
    const selected = content.substring(start, end);

    let replacement = '';
    let newCursorPos = start;

    if (prefix === '• ' || prefix === '[ ] ' || prefix === '1. ' || prefix === '> ') {
      // Line prefix
      replacement = `\n${prefix}${selected}`;
      newCursorPos = start + prefix.length + 1;
    } else {
      // Inline wrap (bold, italic)
      replacement = `${prefix}${selected || 'text'}${suffix}`;
      newCursorPos = selected ? end + prefix.length + suffix.length : start + prefix.length + 4;
    }

    const updated = content.substring(0, start) + replacement + content.substring(end);
    handleContentChange(updated);
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
      <View style={styles.container}>
        <Text style={styles.loadingText}>Loading note...</Text>
      </View>
    );
  }

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      style={styles.container}
    >
      {/* Top Header */}
      <View style={styles.header}>
        <TouchableOpacity style={styles.iconBtn} onPress={onBack}>
          <Ionicons name="arrow-back" size={24} color={colors.text} />
        </TouchableOpacity>

        <View style={styles.headerCenter}>
          <Text style={styles.headerTitle}>{note.title}</Text>
          <Text style={styles.headerSubtitle}>
            {note.dateStr} • {note.timeStr}
          </Text>
        </View>

        <View style={styles.headerRight}>
          <Text style={styles.statusText}>{saveStatus}</Text>
          <TouchableOpacity style={styles.iconBtn} onPress={handleDelete}>
            <Ionicons name="trash-outline" size={22} color={colors.danger} />
          </TouchableOpacity>
        </View>
      </View>

      {/* Editor Body */}
      <ScrollView style={styles.scrollBody} keyboardShouldPersistTaps="handled">
        <TextInput
          ref={inputRef}
          style={styles.textInput}
          multiline
          placeholder="Start writing your thoughts for today..."
          placeholderTextColor={colors.textMuted}
          value={content}
          onChangeText={handleContentChange}
          onSelectionChange={(e) => setCursorPos(e.nativeEvent.selection)}
          textAlignVertical="top"
          autoFocus={!content}
        />
      </ScrollView>

      {/* Rich Formatting Toolbar */}
      <View style={styles.toolbar}>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.toolbarScroll}>
          <TouchableOpacity style={styles.toolBtn} onPress={() => insertFormatting('**', '**')}>
            <Ionicons name="text" size={18} color={colors.text} />
            <Text style={styles.toolLabel}>Bold</Text>
          </TouchableOpacity>

          <TouchableOpacity style={styles.toolBtn} onPress={() => insertFormatting('*', '*')}>
            <Ionicons name="pencil" size={18} color={colors.text} />
            <Text style={styles.toolLabel}>Italic</Text>
          </TouchableOpacity>

          <TouchableOpacity style={styles.toolBtn} onPress={() => insertFormatting('• ')}>
            <Ionicons name="list" size={18} color={colors.text} />
            <Text style={styles.toolLabel}>Bullet</Text>
          </TouchableOpacity>

          <TouchableOpacity style={styles.toolBtn} onPress={() => insertFormatting('[ ] ')}>
            <Ionicons name="checkbox-outline" size={18} color={colors.text} />
            <Text style={styles.toolLabel}>To-Do</Text>
          </TouchableOpacity>

          <TouchableOpacity style={styles.toolBtn} onPress={() => insertFormatting('1. ')}>
            <Ionicons name="reorder-four" size={18} color={colors.text} />
            <Text style={styles.toolLabel}>Numbered</Text>
          </TouchableOpacity>

          <TouchableOpacity style={styles.toolBtn} onPress={() => insertFormatting('> ')}>
            <Ionicons name="chatbox-ellipses-outline" size={18} color={colors.text} />
            <Text style={styles.toolLabel}>Quote</Text>
          </TouchableOpacity>
        </ScrollView>
      </View>
    </KeyboardAvoidingView>
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
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
    backgroundColor: colors.surface,
  },
  headerCenter: {
    flex: 1,
    marginLeft: 12,
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: colors.text,
  },
  headerSubtitle: {
    fontSize: 12,
    color: colors.textSecondary,
    marginTop: 2,
  },
  headerRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  statusText: {
    fontSize: 11,
    color: colors.textMuted,
  },
  iconBtn: {
    padding: 6,
    borderRadius: 8,
  },
  scrollBody: {
    flex: 1,
    padding: 16,
  },
  textInput: {
    color: colors.text,
    fontSize: 16,
    lineHeight: 26,
    minHeight: 300,
  },
  toolbar: {
    borderTopWidth: 1,
    borderTopColor: colors.border,
    backgroundColor: colors.surface,
    paddingVertical: 8,
  },
  toolbarScroll: {
    paddingHorizontal: 12,
    gap: 8,
  },
  toolBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.card,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
    gap: 6,
    borderWidth: 1,
    borderColor: colors.border,
  },
  toolLabel: {
    color: colors.text,
    fontSize: 12,
    fontWeight: '600',
  },
  loadingText: {
    color: colors.textSecondary,
    textAlign: 'center',
    marginTop: 40,
    fontSize: 15,
  },
});
