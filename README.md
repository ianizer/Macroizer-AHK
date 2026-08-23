# Macroizer
An AutoHotkey V1 macro recorder and player with support for playing macros on image detection (e.g., when a button becomes visible on screen).

<img width="802" height="483" alt="image" src="https://github.com/user-attachments/assets/ccf92f9c-07e5-4698-bb83-4619fb2c236c" />

## Instructions
First, you must record or load a macro. To record one, either click "Record" or use the Record hotkey, which defaults to `Ctrl+R`. If the button is clicked, then recording will start after the specified delay.

Alternatively, you may load a saved macro from a file, or create your own macro. See your `C:\Users\[username]\Documents\Macroizer` folder after launching this app for details (a readme.txt file is generated there).

After recording or loading a macro, you may play it by clicking "Play" or using the Play hotkey, which defaults to `Ctrl+Q`. 

You may change the hotkey setting by clicking "Set Hotkeys" and following the dialog that appears. The "Set Hotkeys" button will display the new hotkey settings after you click "Ok".

<img width="340" height="408" alt="image" src="https://github.com/user-attachments/assets/ececc0ff-c323-47d4-b724-3eb34eadb8c0" />

### Playing Macro on Image Detection
Click "More Settings" to open the menu below.

<img width="822" height="548" alt="image" src="https://github.com/user-attachments/assets/c2518cdd-9869-41f0-bcfa-ebe63ef0b073" />

Click "Select Images To Search" to do just that. A file dialog will appear, and you may select multiple image files at a time.

After selecting your images, their full filepaths will appear in the "Images To Search" area. In this area, you may select (click or Ctrl+A) a file in the list and press Delete to remove it from the search list.

Now check "Play macro when image appears on screen?". With that, clicking "Play" or using the Play hotkey _will not play the macro immediately._ Instead, every image check interval (default 5000ms), the program will scan for each image and, if any image is found on the screen, the macro will activate/play.

## Known Issues
- When configured to start on image detection, macros only play if there is an _exact_ match of any of the designated image files.
