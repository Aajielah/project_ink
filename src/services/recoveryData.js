// src/services/recoveryData.js
import AsyncStorage from '@react-native-async-storage/async-storage';

export const RECOVERED_DATA = {
  projects: [
    {
      id: 'proj_1793290062248_ag80f',
      name: '2026',
      year: 2026,
      createdMonthIndex: 9,
      createdAt: '2026-10-29T16:07:42.248Z',
    },
  ],
  monthFolders: [
    {
      id: 'month_1793290062255_r6idm',
      projectId: 'proj_1793290062248_ag80f',
      monthIndex: 9,
      monthName: 'October',
      year: 2026,
      createdAt: '2026-10-29T16:07:42.255Z',
    },
  ],
  weekFolders: [
    {
      id: 'week_1793290062261_4_yy5u',
      monthFolderId: 'month_1793290062255_r6idm',
      projectId: 'proj_1793290062248_ag80f',
      weekNumber: 4,
      label: 'Week 4',
      dateRange: 'Day 22 - 31',
      startDay: 22,
      endDay: 31,
      year: 2026,
      monthIndex: 9,
      createdAt: '2026-10-29T16:07:42.261Z',
    },
  ],
  notes: [
    {
      id: 'note_1793290062270_ho6by',
      weekFolderId: 'week_1793290062261_4_yy5u',
      monthFolderId: 'month_1793290062255_r6idm',
      projectId: 'proj_1793290062248_ag80f',
      title: 'Thursday',
      dayName: 'Thursday',
      dateStr: 'Oct 29, 2026',
      timeStr: '6:52 PM',
      dayNumber: 29,
      content: `Chapter 40

Inside the Grand Imperial Hotel ballroom, the terrified socialites and businessmen scrambled backward toward the walls, knocking over chairs and tables in a mad rush to stay out of the fight.

In the center of the red carpet, the twelve elite martial artists of the Sterling Family surrounded Leon and Dark Knight without leaving a single gap to escape.

Leading the encirclement was Protector Scar, a ruthless Heavenly Realm expert that Patriarch Harold Sterling had spent ten million dollars a year to hire as the family's chief guardian.

"Brat, you should have stayed hidden in whatever rat hole you crawled out of!" Protector Scar sneered coldly, cracking his knuckles as surging Heavenly Realm Qi wrapped around his fists,

"Take him down! Remember Young Master Victor's orders, break his limbs and leave him breathing!" He barked to the eleven Core Formation and Nascent Soul guards around him.

"Yes, Protector Scar!"

Without hesitation, all twelve martial artists lunged forward at the exact same time, their fierce fist winds howling through the air toward Leon's head and chest!

Up on the stage, Victor Sterling crossed his arms over his white tuxedo, a vicious, triumphant grin plastered across his face as he waited to watch Leon get beaten into a crippled dog.

In his mind, not a single person below the Mortal Realm could possibly survive a joint assault from Protector Scar and eleven elite martial guards.

Leon on the other hand didn't even bother taking his hands out of his pockets.

He didn't blink, nor did he take half a step back.

Instead, Leon tilted his head slightly toward the burly figure standing beside him and uttered four cold words,

"Teach him a lesson."

"Understood, Supreme Commander," Dark Knight answered with a cruel smirk tugged at the corner of his mouth.

The next second, Dark Knight took a single step forward, placing himself right in front of Leon as his eyes flashed with a terrifying golden light.

He didn't even bother throwing a punch.

Against a bunch of ants whose strongest fighter was barely in the Heavenly Realm, using his fists would be an insult to his newly awakened realm.

Dark Knight simply released a tiny fraction of his False Immortal Realm spiritual pressure!

In an instant, the air inside the grand ballroom turned as heavy as liquid lead, and an invisible mountain seemed to crash straight down from the heavens onto the red carpet!

"What the heck is this aura?!" Protector Scar's arrogant expression vanished in a split second, his eyes nearly popping out of their sockets in pure horror!

Before he or any of the eleven guards could even stop their forward momentum, the suffocating False Immortal pressure slammed squarely into their bodies!

A chorus of sickening bone-snapping sounds echoed across the dead-silent hall!

Like flies swatted out of the air by an iron fan, all eleven Core Formation and Nascent Soul guards were flattened straight onto the marble floor in mid-air!

Blood spurted from their mouths and noses like fountains as they crashed down, their chests collapsing under the sheer gravitational weight!`,
      createdAt: '2026-10-29T16:07:42.270Z',
      updatedAt: '2026-10-29T17:52:10.000Z',
    },
  ],
};

export async function restoreRecoveredChapterData() {
  await AsyncStorage.setItem('@daily_notes_projects', JSON.stringify(RECOVERED_DATA.projects));
  await AsyncStorage.setItem('@daily_notes_months', JSON.stringify(RECOVERED_DATA.monthFolders));
  await AsyncStorage.setItem('@daily_notes_weeks', JSON.stringify(RECOVERED_DATA.weekFolders));
  await AsyncStorage.setItem('@daily_notes_notes', JSON.stringify(RECOVERED_DATA.notes));
  return true;
}
