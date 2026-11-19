// src/utils/textStyler.js

/**
 * Converts ASCII alphanumeric characters to Unicode Sans-Serif Bold.
 * Renders as actual bold across any plain text input without syntax like **...**.
 */
export function toSansBold(text) {
  if (!text) return '';
  const clean = text.replace(/^\*\*|\*\*$/g, '');
  return clean
    .split('')
    .map((char) => {
      const code = char.charCodeAt(0);
      // 0-9: 0x1D7EC - 0x1D7F5
      if (code >= 48 && code <= 57) {
        return String.fromCodePoint(0x1D7EC + (code - 48));
      }
      // A-Z: 0x1D5D4 - 0x1D5ED
      if (code >= 65 && code <= 90) {
        return String.fromCodePoint(0x1D5D4 + (code - 65));
      }
      // a-z: 0x1D5EE - 0x1D607
      if (code >= 97 && code <= 122) {
        return String.fromCodePoint(0x1D5EE + (code - 97));
      }
      return char;
    })
    .join('');
}

/**
 * Converts ASCII characters to Unicode Mathematical Italic.
 * Renders as actual italic without syntax like *...*.
 */
export function toItalic(text) {
  if (!text) return '';
  const clean = text.replace(/^\*|\*$/g, '');
  return clean
    .split('')
    .map((char) => {
      const code = char.charCodeAt(0);
      // A-Z: 0x1D434 - 0x1D44D
      if (code >= 65 && code <= 90) {
        return String.fromCodePoint(0x1D434 + (code - 65));
      }
      // a-z: 0x1D44E - 0x1D467 (note: 'h' is Planck constant 0x210E)
      if (code >= 97 && code <= 122) {
        if (char === 'h') return 'ℎ';
        return String.fromCodePoint(0x1D44E + (code - 97));
      }
      return char;
    })
    .join('');
}

/**
 * Converts any stylized Unicode bold/italic characters back to standard ASCII.
 */
export function unstyle(text) {
  if (!text) return '';
  let result = '';
  for (const char of text) {
    const cp = char.codePointAt(0);
    // Sans-serif bold 0-9: 0x1D7EC - 0x1D7F5
    if (cp >= 0x1D7EC && cp <= 0x1D7F5) {
      result += String.fromCharCode(48 + (cp - 0x1D7EC));
    }
    // Serif bold 0-9: 0x1D7CE - 0x1D7D7
    else if (cp >= 0x1D7CE && cp <= 0x1D7D7) {
      result += String.fromCharCode(48 + (cp - 0x1D7CE));
    }
    // Sans-serif bold A-Z: 0x1D5D4 - 0x1D5ED
    else if (cp >= 0x1D5D4 && cp <= 0x1D5ED) {
      result += String.fromCharCode(65 + (cp - 0x1D5D4));
    }
    // Serif bold A-Z: 0x1D400 - 0x1D419
    else if (cp >= 0x1D400 && cp <= 0x1D419) {
      result += String.fromCharCode(65 + (cp - 0x1D400));
    }
    // Sans-serif bold a-z: 0x1D5EE - 0x1D607
    else if (cp >= 0x1D5EE && cp <= 0x1D607) {
      result += String.fromCharCode(97 + (cp - 0x1D5EE));
    }
    // Serif bold a-z: 0x1D41A - 0x1D433
    else if (cp >= 0x1D41A && cp <= 0x1D433) {
      result += String.fromCharCode(97 + (cp - 0x1D41A));
    }
    // Italic A-Z: 0x1D434 - 0x1D44D
    else if (cp >= 0x1D434 && cp <= 0x1D44D) {
      result += String.fromCharCode(65 + (cp - 0x1D434));
    }
    // Italic a-z: 0x1D44E - 0x1D467
    else if (cp >= 0x1D44E && cp <= 0x1D467) {
      result += String.fromCharCode(97 + (cp - 0x1D44E));
    } else if (char === 'ℎ') {
      result += 'h';
    } else {
      result += char;
    }
  }
  return result;
}

export function isBold(text) {
  if (!text) return false;
  for (const char of text) {
    const cp = char.codePointAt(0);
    if (
      (cp >= 0x1D7EC && cp <= 0x1D7F5) ||
      (cp >= 0x1D7CE && cp <= 0x1D7D7) ||
      (cp >= 0x1D5D4 && cp <= 0x1D5ED) ||
      (cp >= 0x1D400 && cp <= 0x1D419) ||
      (cp >= 0x1D5EE && cp <= 0x1D607) ||
      (cp >= 0x1D41A && cp <= 0x1D433)
    ) {
      return true;
    }
  }
  return false;
}

export function isItalic(text) {
  if (!text) return false;
  for (const char of text) {
    const cp = char.codePointAt(0);
    if (
      (cp >= 0x1D434 && cp <= 0x1D44D) ||
      (cp >= 0x1D44E && cp <= 0x1D467) ||
      char === 'ℎ'
    ) {
      return true;
    }
  }
  return false;
}

export function toggleBold(text) {
  if (isBold(text)) {
    return unstyle(text);
  }
  return toSansBold(text);
}

export function toggleItalic(text) {
  if (isItalic(text)) {
    return unstyle(text);
  }
  return toItalic(text);
}

/**
 * Formats a time string (e.g. "10:45 AM") into real bold Unicode.
 */
export function formatBoldTimestamp(timeStr, includeBrackets = true) {
  if (!timeStr) return '';
  const boldTime = toSansBold(timeStr.trim());
  return includeBrackets ? `[${boldTime}]` : boldTime;
}

/**
 * Gets formatted current time like "04:15 PM" or "10:45 AM"
 */
export function getCurrentFormattedTime() {
  const now = new Date();
  let hours = now.getHours();
  const minutes = now.getMinutes();
  const ampm = hours >= 12 ? 'PM' : 'AM';
  hours = hours % 12;
  hours = hours ? hours : 12;
  const strHours = hours < 10 ? '0' + hours : String(hours);
  const strMinutes = minutes < 10 ? '0' + minutes : String(minutes);
  return `${strHours}:${strMinutes} ${ampm}`;
}

/**
 * Finds the next number for a numbered list preceding the given cursor position.
 */
export function getNextListNumber(content, cursorIndex) {
  if (!content) return 1;
  const beforeCursor = content.substring(0, cursorIndex);
  const lines = beforeCursor.split('\n');

  // Look backwards through lines to find the most recent numbered item
  for (let i = lines.length - 1; i >= 0; i--) {
    const line = lines[i].trim();
    // Also unstyle in case user has unicode bold numbers like "𝟭. "
    const unstyledLine = unstyle(line);
    const match = unstyledLine.match(/^(\d+)\./);
    if (match) {
      return parseInt(match[1], 10) + 1;
    }
  }
  return 1;
}

/**
 * Handles smart newline list continuation.
 * When a user hits Enter in a list, automatically appends next number or bullet.
 * If user hits Enter on an empty list item, cancels the list.
 */
export function handleSmartListNewline(oldText, newText, cursorPos) {
  if (newText.length !== oldText.length + 1) return null;

  // Determine where the newline character was inserted
  let insertIdx =
    cursorPos &&
    cursorPos.start >= 0 &&
    cursorPos.start < newText.length &&
    newText[cursorPos.start] === '\n'
      ? cursorPos.start
      : -1;

  if (insertIdx === -1) {
    let p = 0;
    while (p < oldText.length && oldText[p] === newText[p]) p++;
    if (newText[p] === '\n') {
      insertIdx = p;
    } else {
      return null;
    }
  }

  const beforeNewline = newText.substring(0, insertIdx);
  const lastLineStart = beforeNewline.lastIndexOf('\n') + 1;
  const prevLine = beforeNewline.substring(lastLineStart);
  const unstyledPrevLine = unstyle(prevLine);

  // 1. Numbered list: e.g. "1. Hello" or "1. " or "𝟭. "
  const numMatch = unstyledPrevLine.match(/^(\s*)(\d+)\.\s*(.*)$/);
  if (numMatch) {
    const indent = numMatch[1];
    const num = parseInt(numMatch[2], 10);
    const itemContent = numMatch[3].trim();

    if (itemContent === '') {
      // Empty item: cancel list item and leave blank line
      const updated = newText.substring(0, lastLineStart) + newText.substring(insertIdx + 1);
      return {
        updatedText: updated,
        newCursor: lastLineStart,
      };
    } else {
      // Non-empty item: increment number!
      const nextNum = num + 1;
      const continuation = `${indent}${nextNum}. `;
      const updated = newText.substring(0, insertIdx + 1) + continuation + newText.substring(insertIdx + 1);
      return {
        updatedText: updated,
        newCursor: insertIdx + 1 + continuation.length,
      };
    }
  }

  // 2. Bullet list: e.g. "• Hello" or "- Hello"
  const bulletMatch = unstyledPrevLine.match(/^(\s*)(•|-|\*)\s*(.*)$/);
  if (bulletMatch) {
    const indent = bulletMatch[1];
    const itemContent = bulletMatch[3].trim();
    if (itemContent === '') {
      const updated = newText.substring(0, lastLineStart) + newText.substring(insertIdx + 1);
      return { updatedText: updated, newCursor: lastLineStart };
    } else {
      const continuation = `${indent}• `;
      const updated = newText.substring(0, insertIdx + 1) + continuation + newText.substring(insertIdx + 1);
      return { updatedText: updated, newCursor: insertIdx + 1 + continuation.length };
    }
  }

  // 3. To-Do checklist: e.g. "[ ] Hello"
  const todoMatch = unstyledPrevLine.match(/^(\s*)\[([ x])\]\s*(.*)$/);
  if (todoMatch) {
    const indent = todoMatch[1];
    const itemContent = todoMatch[3].trim();
    if (itemContent === '') {
      const updated = newText.substring(0, lastLineStart) + newText.substring(insertIdx + 1);
      return { updatedText: updated, newCursor: lastLineStart };
    } else {
      const continuation = `${indent}[ ] `;
      const updated = newText.substring(0, insertIdx + 1) + continuation + newText.substring(insertIdx + 1);
      return { updatedText: updated, newCursor: insertIdx + 1 + continuation.length };
    }
  }

  return null;
}

/**
 * Applies active formatting (Bold or Italic mode like MS Word Ctrl+B / Ctrl+I)
 * to newly typed characters.
 */
export function applyActiveFormatting(oldText, newText, cursorPos, isBoldActive, isItalicActive) {
  if (!isBoldActive && !isItalicActive) return null;
  if (newText.length <= oldText.length) return null;

  let start =
    cursorPos && cursorPos.start >= 0 && cursorPos.start <= oldText.length
      ? cursorPos.start
      : -1;

  if (start === -1) {
    let p = 0;
    while (p < oldText.length && oldText[p] === newText[p]) p++;
    start = p;
  }

  const charsInserted = newText.length - oldText.length;
  if (charsInserted <= 0) return null;

  const inserted = newText.substring(start, start + charsInserted);
  // Don't style newlines so list continuations aren't affected
  if (inserted === '\n') return null;

  let styled = inserted;
  if (isBoldActive) {
    styled = toSansBold(styled);
  }
  if (isItalicActive) {
    styled = toItalic(styled);
  }

  if (styled === inserted) return null;

  const updated = newText.substring(0, start) + styled + newText.substring(start + charsInserted);
  const newCursor = start + styled.length;
  return { updatedText: updated, newCursor };
}

