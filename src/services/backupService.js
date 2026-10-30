// src/services/backupService.js
import AsyncStorage from '@react-native-async-storage/async-storage';
import { storage } from '../storage/storageManager';
import { financeManager } from '../storage/financeManager';

/**
 * Pure JS Key-based Cipher for secure portable export/import
 * (Compatible with Daily_Counter encrypted payload philosophy)
 */
function deriveKey(password, salt) {
  let hash = 0;
  const str = password + salt + '_daily_notes_secure';
  const keyBytes = [];
  for (let i = 0; i < str.length; i++) {
    hash = (hash << 5) - hash + str.charCodeAt(i);
    hash |= 0;
    keyBytes.push(Math.abs(hash) % 256);
  }
  while (keyBytes.length < 32) {
    keyBytes.push((keyBytes[keyBytes.length - 1] * 31 + 17) % 256);
  }
  return keyBytes;
}

function encryptText(plainText, password) {
  const salt = 'dn_' + Math.random().toString(36).substring(2, 8);
  const key = deriveKey(password, salt);
  const encBytes = [];

  for (let i = 0; i < plainText.length; i++) {
    const charCode = plainText.charCodeAt(i);
    const keyByte = key[i % key.length];
    encBytes.push(charCode ^ keyByte);
  }

  const payloadObj = {
    salt,
    magic: 'DN_ENC_V1',
    data: encBytes,
    checksum: simpleHash(plainText),
  };

  const jsonStr = JSON.stringify(payloadObj);
  // Base64 encode
  if (typeof btoa !== 'undefined') {
    return btoa(unescape(encodeURIComponent(jsonStr)));
  }
  return Buffer.from(jsonStr).toString('base64');
}

function decryptText(base64Payload, password) {
  // Strip markdown fences, spaces, newlines, and any accidental non-base64 characters
  const cleanPayload = (base64Payload || '').replace(/[^A-Za-z0-9+/=]/g, '');
  if (!cleanPayload) {
    return { error: 'Backup code is empty or contains no valid data.' };
  }

  let jsonStr = '';
  try {
    if (typeof atob !== 'undefined') {
      jsonStr = decodeURIComponent(escape(atob(cleanPayload)));
    } else {
      jsonStr = Buffer.from(cleanPayload, 'base64').toString('utf8');
    }
  } catch (e) {
    return { error: 'Invalid backup encoding. The text was truncated or corrupted during copy/paste.' };
  }

  let payloadObj;
  try {
    payloadObj = JSON.parse(jsonStr);
  } catch (e) {
    return { error: 'Incomplete backup data. Make sure the entire code was copied.' };
  }

  if (!payloadObj || payloadObj.magic !== 'DN_ENC_V1') {
    return { error: 'Unrecognized backup format.' };
  }

  const key = deriveKey(password, payloadObj.salt);
  const charCodes = [];

  for (let i = 0; i < payloadObj.data.length; i++) {
    const keyByte = key[i % key.length];
    charCodes.push(payloadObj.data[i] ^ keyByte);
  }

  let decrypted = '';
  const CHUNK_SIZE = 4096;
  for (let i = 0; i < charCodes.length; i += CHUNK_SIZE) {
    decrypted += String.fromCharCode.apply(null, charCodes.slice(i, i + CHUNK_SIZE));
  }

  if (simpleHash(decrypted) !== payloadObj.checksum) {
    return { error: 'Incorrect password entered.' };
  }

  return { success: true, data: decrypted };
}

function simpleHash(str) {
  let hash = 5381;
  for (let i = 0; i < str.length; i++) {
    hash = (hash * 33) ^ str.charCodeAt(i);
  }
  return (hash >>> 0).toString(16);
}

export class BackupService {
  /**
   * Exports all collections (Notes, Tasks, Finances) into an encrypted Base64 string.
   */
  static async exportEncryptedBackup(password) {
    const projects = await storage.getProjects();
    const monthFolders = await storage.getMonthFolders();
    const weekFolders = await storage.getWeekFolders();
    const notes = await storage.getNotes();
    const trash = await storage.getTrash();
    const tasks = await storage.getTasks();
    const financeConfig = await financeManager.getConfig();
    const financeSheets = await financeManager.getAllSheets();

    const fullPayload = {
      version: 1,
      appName: 'Daily Notes',
      exportedAt: new Date().toISOString(),
      data: {
        projects,
        monthFolders,
        weekFolders,
        notes,
        trash,
        tasks,
        financeConfig,
        financeSheets,
      },
    };

    const rawJson = JSON.stringify(fullPayload);
    return encryptText(rawJson, password);
  }

  /**
   * Decrypts and restores backup into storage.
   */
  static async importEncryptedBackup(encryptedBase64, password) {
    try {
      const decRes = decryptText(encryptedBase64, password);
      if (decRes.error) {
        return { success: false, error: decRes.error };
      }

      const decryptedJson = decRes.data;

      const parsed = JSON.parse(decryptedJson);
      if (!parsed.data) {
        return { success: false, error: 'Invalid backup structure.' };
      }

      const {
        projects,
        monthFolders,
        weekFolders,
        notes,
        trash,
        tasks,
        financeConfig,
        financeSheets,
      } = parsed.data;

      if (projects) await AsyncStorage.setItem('@daily_notes_projects', JSON.stringify(projects));
      if (monthFolders) await AsyncStorage.setItem('@daily_notes_months', JSON.stringify(monthFolders));
      if (weekFolders) await AsyncStorage.setItem('@daily_notes_weeks', JSON.stringify(weekFolders));
      if (notes) await AsyncStorage.setItem('@daily_notes_notes', JSON.stringify(notes));
      if (trash) await AsyncStorage.setItem('@daily_notes_trash', JSON.stringify(trash));
      if (tasks) await AsyncStorage.setItem('@daily_notes_tasks', JSON.stringify(tasks));
      if (financeConfig) await AsyncStorage.setItem('@daily_notes_finance_config', JSON.stringify(financeConfig));
      if (financeSheets) await AsyncStorage.setItem('@daily_notes_finance_sheets', JSON.stringify(financeSheets));

      return { success: true };
    } catch (e) {
      console.error('Import error', e);
      return { success: false, error: e.message || 'Decryption failed.' };
    }
  }
}
