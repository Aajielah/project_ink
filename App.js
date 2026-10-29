// App.js
import React, { useState, useEffect } from 'react';
import {
  StyleSheet,
  View,
  Text,
  TouchableOpacity,
} from 'react-native';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import { StatusBar } from 'expo-status-bar';
import { Ionicons } from '@expo/vector-icons';
import { ThemeProvider, useTheme } from './src/theme/ThemeContext';
import { storage } from './src/storage/storageManager';

import HomeScreen from './src/screens/HomeScreen';
import TasksScreen from './src/screens/TasksScreen';
import FinancesScreen from './src/screens/FinancesScreen';
import SettingsScreen from './src/screens/SettingsScreen';

function MainApp() {
  const { theme, isDarkMode } = useTheme();
  const [activeTab, setActiveTab] = useState('home'); // 'home' | 'tasks' | 'finances' | 'settings'

  useEffect(() => {
    const initApp = async () => {
      await storage.purgeExpiredTrash();
      await storage.runMidnightTaskReset();
      await storage.ensureDailyNotesGenerated();
    };
    initApp();
  }, []);

  return (
    <SafeAreaView
      style={[styles.container, { backgroundColor: theme.background }]}
      edges={['top', 'left', 'right', 'bottom']}
    >
      <StatusBar
        style={isDarkMode ? 'light' : 'dark'}
        backgroundColor={theme.surface}
      />

      {/* Main Content Area */}
      <View style={styles.content}>
        {activeTab === 'home' && <HomeScreen />}
        {activeTab === 'tasks' && <TasksScreen />}
        {activeTab === 'finances' && <FinancesScreen />}
        {activeTab === 'settings' && <SettingsScreen />}
      </View>

      {/* Bottom Tab Navigation Bar */}
      <View
        style={[
          styles.tabBar,
          {
            backgroundColor: theme.surface,
            borderTopColor: theme.border,
          },
        ]}
      >
        <TouchableOpacity
          style={styles.tabItem}
          activeOpacity={0.7}
          onPress={() => setActiveTab('home')}
        >
          <Ionicons
            name={activeTab === 'home' ? 'albums' : 'albums-outline'}
            size={22}
            color={activeTab === 'home' ? theme.primary : theme.textMuted}
          />
          <Text
            style={[
              styles.tabLabel,
              { color: activeTab === 'home' ? theme.primary : theme.textMuted },
              activeTab === 'home' && styles.tabLabelActive,
            ]}
          >
            Home
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.tabItem}
          activeOpacity={0.7}
          onPress={() => setActiveTab('tasks')}
        >
          <Ionicons
            name={activeTab === 'tasks' ? 'checkbox' : 'checkbox-outline'}
            size={22}
            color={activeTab === 'tasks' ? theme.primary : theme.textMuted}
          />
          <Text
            style={[
              styles.tabLabel,
              { color: activeTab === 'tasks' ? theme.primary : theme.textMuted },
              activeTab === 'tasks' && styles.tabLabelActive,
            ]}
          >
            Tasks
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.tabItem}
          activeOpacity={0.7}
          onPress={() => setActiveTab('finances')}
        >
          <Ionicons
            name={activeTab === 'finances' ? 'wallet' : 'wallet-outline'}
            size={22}
            color={activeTab === 'finances' ? theme.primary : theme.textMuted}
          />
          <Text
            style={[
              styles.tabLabel,
              { color: activeTab === 'finances' ? theme.primary : theme.textMuted },
              activeTab === 'finances' && styles.tabLabelActive,
            ]}
          >
            Finances
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.tabItem}
          activeOpacity={0.7}
          onPress={() => setActiveTab('settings')}
        >
          <Ionicons
            name={activeTab === 'settings' ? 'settings' : 'settings-outline'}
            size={22}
            color={activeTab === 'settings' ? theme.primary : theme.textMuted}
          />
          <Text
            style={[
              styles.tabLabel,
              { color: activeTab === 'settings' ? theme.primary : theme.textMuted },
              activeTab === 'settings' && styles.tabLabelActive,
            ]}
          >
            Settings
          </Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}

export default function App() {
  return (
    <SafeAreaProvider>
      <ThemeProvider>
        <MainApp />
      </ThemeProvider>
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  content: {
    flex: 1,
  },
  tabBar: {
    flexDirection: 'row',
    borderTopWidth: 1,
    paddingVertical: 8,
    paddingBottom: 8,
  },
  tabItem: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 4,
  },
  tabLabel: {
    fontSize: 11,
    marginTop: 4,
    fontWeight: '500',
  },
  tabLabelActive: {
    fontWeight: '700',
  },
});
