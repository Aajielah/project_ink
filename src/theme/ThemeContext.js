// src/theme/ThemeContext.js
import React, { createContext, useContext, useState, useEffect } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { lightTheme, darkTheme } from './colors';

const THEME_STORAGE_KEY = '@daily_notes_theme_mode';

const ThemeContext = createContext({
  theme: lightTheme,
  isDarkMode: false,
  toggleTheme: () => {},
  setThemeMode: () => {},
});

export function ThemeProvider({ children }) {
  const [isDarkMode, setIsDarkMode] = useState(false); // Default to clean Light mode

  useEffect(() => {
    loadSavedTheme();
  }, []);

  const loadSavedTheme = async () => {
    try {
      const saved = await AsyncStorage.getItem(THEME_STORAGE_KEY);
      if (saved !== null) {
        setIsDarkMode(saved === 'dark');
      }
    } catch (e) {
      console.error('Error loading saved theme', e);
    }
  };

  const toggleTheme = async () => {
    const nextMode = !isDarkMode;
    setIsDarkMode(nextMode);
    try {
      await AsyncStorage.setItem(THEME_STORAGE_KEY, nextMode ? 'dark' : 'light');
    } catch (e) {
      console.error('Error saving theme', e);
    }
  };

  const setThemeMode = async (mode) => {
    const nextMode = mode === 'dark';
    setIsDarkMode(nextMode);
    try {
      await AsyncStorage.setItem(THEME_STORAGE_KEY, mode);
    } catch (e) {
      console.error('Error saving theme', e);
    }
  };

  const currentTheme = isDarkMode ? darkTheme : lightTheme;

  return (
    <ThemeContext.Provider
      value={{
        theme: currentTheme,
        isDarkMode,
        toggleTheme,
        setThemeMode,
      }}
    >
      {children}
    </ThemeContext.Provider>
  );
}

export function useTheme() {
  return useContext(ThemeContext);
}
