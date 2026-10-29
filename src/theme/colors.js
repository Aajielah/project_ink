// src/theme/colors.js

export const lightTheme = {
  isDark: false,
  background: '#F8FAFC',
  surface: '#FFFFFF',
  surfaceHover: '#F1F5F9',
  card: '#FFFFFF',
  border: '#E2E8F0',
  borderLight: '#CBD5E1',

  primary: '#4F46E5', // Vibrant Indigo
  primaryHover: '#4338CA',
  primaryLight: 'rgba(79, 70, 229, 0.1)',

  secondary: '#10B981', // Fresh Emerald
  secondaryLight: 'rgba(16, 185, 129, 0.12)',

  text: '#0F172A', // Slate 900
  textSecondary: '#475569', // Slate 600
  textMuted: '#94A3B8', // Slate 400

  danger: '#EF4444',
  dangerLight: 'rgba(239, 68, 68, 0.12)',

  warning: '#F59E0B',
  warningLight: 'rgba(245, 158, 11, 0.12)',

  white: '#FFFFFF',
  black: '#000000',
  statusBar: 'dark',
  shadowColor: 'rgba(15, 23, 42, 0.08)',
};

export const darkTheme = {
  isDark: true,
  background: '#0B0F19', // Rich midnight slate
  surface: '#151C2C', // Deep elevated surface
  surfaceHover: '#1E293B',
  card: '#151C2C',
  border: '#232E42',
  borderLight: '#334155',

  primary: '#6366F1', // Indigo
  primaryHover: '#4F46E5',
  primaryLight: 'rgba(99, 102, 241, 0.15)',

  secondary: '#10B981', // Emerald
  secondaryLight: 'rgba(16, 185, 129, 0.15)',

  text: '#F8FAFC',
  textSecondary: '#94A3B8',
  textMuted: '#64748B',

  danger: '#EF4444',
  dangerLight: 'rgba(239, 68, 68, 0.15)',

  warning: '#F59E0B',
  warningLight: 'rgba(245, 158, 11, 0.15)',

  white: '#FFFFFF',
  black: '#000000',
  statusBar: 'light',
  shadowColor: '#000000',
};

export const colors = lightTheme;
