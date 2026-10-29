// src/screens/WeekNotesScreen.js
import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  FlatList,
  StyleSheet,
  Alert,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useTheme } from '../theme/ThemeContext';
import { storage } from '../storage/storageManager';
import { isWeekExpired, isWeekActive } from '../utils/dateUtils';

export default function WeekNotesScreen({
  week,
  month,
  project,
  onBack,
  onSelectNote,
}) {
  const { theme } = useTheme();
  const [notes, setNotes] = useState([]);
  const [expired, setExpired] = useState(false);
  const [active, setActive] = useState(false);

  useEffect(() => {
    checkWeekStatus();
    loadNotes();
  }, [week]);

  const checkWeekStatus = () => {
    const isExp = isWeekExpired(week.year, week.monthIndex, week, new Date());
    const isAct = isWeekActive(week.year, week.monthIndex, week, new Date());
    setExpired(isExp);
    setActive(isAct);
  };

  const loadNotes = async () => {
    const loaded = await storage.getNotes(week.id);
    setNotes(loaded);
  };

  const handleCreateNote = async () => {
    if (expired) {
      Alert.alert(
        'Week Expired',
        'This week has ended. No new notes can be created in an expired week.'
      );
      return;
    }

    const maxNotes = week.endDay - week.startDay + 1;
    if (notes.length >= maxNotes) {
      Alert.alert(
        'Limit Reached',
        `This week is limited to ${maxNotes} notes (one for each day).`
      );
      return;
    }

    try {
      const newNote = await storage.createNote({
        weekFolderId: week.id,
        monthFolderId: week.monthFolderId,
        projectId: week.projectId,
        content: '',
        customDate: new Date(),
      });
      await loadNotes();
      onSelectNote(newNote.id);
    } catch (err) {
      Alert.alert('Notice', err.message);
    }
  };

  const handleDeleteNote = (noteId, e) => {
    e.stopPropagation();
    Alert.alert(
      'Move to Trash',
      'Move this note to Trash? It will remain available for 30 days.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Trash',
          style: 'destructive',
          onPress: async () => {
            await storage.deleteNote(noteId);
            await loadNotes();
          },
        },
      ]
    );
  };

  const renderNoteCard = ({ item }) => (
    <TouchableOpacity
      style={[
        styles.noteCard,
        { backgroundColor: theme.card, borderColor: theme.border },
      ]}
      activeOpacity={0.7}
      onPress={() => onSelectNote(item.id)}
    >
      <View style={styles.noteCardHeader}>
        <View style={styles.titleRow}>
          <Ionicons name="document-text-outline" size={20} color={theme.primary} />
          <Text style={[styles.noteTitle, { color: theme.text }]}>{item.title}</Text>
        </View>
        <TouchableOpacity
          style={styles.trashBtn}
          onPress={(e) => handleDeleteNote(item.id, e)}
        >
          <Ionicons name="trash-outline" size={18} color={theme.textMuted} />
        </TouchableOpacity>
      </View>

      <Text style={[styles.noteSnippet, { color: theme.textSecondary }]} numberOfLines={2}>
        {item.content ? item.content.trim() : 'Tap to write notes for today...'}
      </Text>

      <View style={[styles.cardFooter, { borderTopColor: theme.border }]}>
        <Text style={[styles.dateTimeText, { color: theme.textMuted }]}>
          {item.dateStr} • {item.timeStr}
        </Text>
      </View>
    </TouchableOpacity>
  );

  const maxNotes = week.endDay - week.startDay + 1;
  const now = new Date();
  const isCurrentMonthAndYear =
    now.getFullYear() === week.year && now.getMonth() === week.monthIndex;
  const currentDayNumber = now.getDate();
  const hasTodayNote =
    isCurrentMonthAndYear && notes.some((n) => n.dayNumber === currentDayNumber);

  const canCreateNote = active && !expired && !hasTodayNote && notes.length < maxNotes;

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      {/* Top Header */}
      <View style={[styles.header, { backgroundColor: theme.surface, borderBottomColor: theme.border }]}>
        <TouchableOpacity style={styles.backBtn} onPress={onBack}>
          <Ionicons name="arrow-back" size={24} color={theme.text} />
        </TouchableOpacity>
        <View style={styles.headerTitles}>
          <Text style={[styles.headerTitle, { color: theme.text }]}>{week.label}</Text>
          <Text style={[styles.headerSubtitle, { color: theme.textSecondary }]}>
            {month.monthName} {month.year} • {week.dateRange}
          </Text>
        </View>
        {active && (
          <View style={[styles.activePill, { backgroundColor: theme.secondaryLight, borderColor: theme.secondary }]}>
            <Text style={[styles.activePillText, { color: theme.secondary }]}>
              {hasTodayNote ? "Today's Note Done" : 'Active Week'}
            </Text>
          </View>
        )}
      </View>

      {/* Week Expired Banner */}
      {expired && (
        <View style={[styles.expiredBanner, { backgroundColor: theme.warningLight, borderBottomColor: theme.border }]}>
          <Ionicons name="lock-closed" size={18} color={theme.warning} />
          <Text style={[styles.expiredText, { color: theme.warning }]}>
            This week has ended. No new notes can be created, but you can view, edit, or delete existing notes.
          </Text>
        </View>
      )}

      {/* Notes List */}
      <FlatList
        data={notes}
        keyExtractor={(item) => item.id}
        renderItem={renderNoteCard}
        contentContainerStyle={styles.listContainer}
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Ionicons name="calendar-outline" size={48} color={theme.textMuted} />
            <Text style={[styles.emptyTitle, { color: theme.text }]}>No notes for this week yet</Text>
            <Text style={[styles.emptySub, { color: theme.textMuted }]}>
              {expired
                ? 'This week ended with no notes.'
                : hasTodayNote
                ? "Today's note has already been recorded."
                : 'Notes are automatically created daily, or tap + to start today\'s note.'}
            </Text>
          </View>
        }
      />

      {/* Floating Plus Button (Strict rule: Hidden as long as today has a note, or week is expired/full) */}
      {canCreateNote && (
        <TouchableOpacity
          style={[styles.fab, { backgroundColor: theme.primary }]}
          activeOpacity={0.8}
          onPress={handleCreateNote}
        >
          <Ionicons name="add" size={32} color="#FFFFFF" />
        </TouchableOpacity>
      )}
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
    fontSize: 18,
    fontWeight: '700',
  },
  headerSubtitle: {
    fontSize: 12,
    marginTop: 2,
  },
  activePill: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
    borderWidth: 1,
  },
  activePillText: {
    fontSize: 11,
    fontWeight: '600',
  },
  expiredBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderBottomWidth: 1,
    gap: 10,
  },
  expiredText: {
    flex: 1,
    fontSize: 12,
    lineHeight: 18,
  },
  listContainer: {
    padding: 16,
    paddingBottom: 90,
  },
  noteCard: {
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    borderWidth: 1,
  },
  noteCardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  noteTitle: {
    fontSize: 17,
    fontWeight: '700',
  },
  trashBtn: {
    padding: 6,
  },
  noteSnippet: {
    fontSize: 14,
    lineHeight: 20,
    marginBottom: 12,
  },
  cardFooter: {
    borderTopWidth: 1,
    paddingTop: 8,
  },
  dateTimeText: {
    fontSize: 11,
  },
  emptyContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 60,
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
});
