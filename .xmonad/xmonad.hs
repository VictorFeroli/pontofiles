--
-- Imports
--
import XMonad
import System.IO (hPutStrLn)
import System.Exit (exitSuccess)
import qualified XMonad.StackSet as W
import qualified Data.Map        as M

  -- Actions
import XMonad.Actions.CopyWindow (kill1)
-- import XMonad.Actions.MouseResize (mouseResize)
import qualified XMonad.Actions.FlexibleResize as Flex

  -- Hooks
import XMonad.Hooks.EwmhDesktops (ewmh)
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.SetWMName (setWMName)
import XMonad.Hooks.ManageHelpers (isFullscreen, doFullFloat, doCenterFloat)

  -- Util
import XMonad.Util.EZConfig (additionalKeysP)
import XMonad.Util.Ungrab (unGrab)
import XMonad.Util.Dmenu
import XMonad.Util.Run (hPutStrLn, spawnPipe)
import XMonad.Util.SpawnOnce (spawnOnce)

  -- Layout
import XMonad.Layout.ThreeColumns (ThreeCol(..))
import XMonad.Layout.Magnifier (magnifiercz')
import XMonad.Layout.NoBorders (smartBorders)
import XMonad.Layout.Spacing (spacingRaw, Border(..))
-- import XMonad.Layout.LayoutModifier
import XMonad.Layout.Renamed (renamed, Rename(Replace))
import XMonad.Layout.SimplestFloat (simplestFloat)
import XMonad.Layout.Spiral (spiral)
import XMonad.Layout.ResizableTile (ResizableTall(..), MirrorResize(..))

--
-- Variables
--
myTerminal = "st"

myWorkspaces = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"]

myBorderWidth = 1


myLauncher :: String
myLauncher = "dmenu_run -i -fn 'SF Mono:pixelsize=12' -bw 1 -h 22 -l 7 -g 1 -p 'Run:' -nb '#3B4252' -nf '#D8DEE9' -sb '#81A1C1' -sf '#2E3440'"

myNormalBorderColor  = "#4C566A"
myFocusedBorderColor = "#D8DEE9"

volumeLower :: String
volumeLower = "pactl set-sink-volume @DEFAULT_SINK@ -5%"

volumeRaise :: String
volumeRaise = "pactl set-sink-volume @DEFAULT_SINK@ +5%"

volumeMute :: String
volumeMute = "pactl set-sink-mute @DEFAULT_SINK@ toggle"

--
-- Layouts
--
mySpacing = spacingRaw True (Border 4 4 4 4) True (Border 4 4 4 4) True

  -- My Layouts
tall       = renamed [Replace "tall"]
           $ smartBorders
           $ mySpacing
           $ ResizableTall 1 (3/100) (1/2) []

spirals    = renamed [Replace "spirals"]
           $ smartBorders
           $ mySpacing
           $ spiral (6/7)

columns    = renamed [Replace "columns"]
           $ smartBorders
           $ mySpacing
           $ magnifiercz' 1.2
           $ ThreeColMid 1 (3/100) (1/2)

floats     = renamed [Replace "floats"]
           $ simplestFloat

myLayout =  avoidStruts $ myLayoutsHook
         where
           myLayoutsHook =     tall
                           ||| Mirror tall
                           ||| spirals
                           ||| columns
                           ||| floats
                           ||| Full

--
-- Windows rules
--
myManageHook = composeAll
    [ className =? "confirm"         --> doFloat
    , className =? "file_progress"   --> doFloat
    , className =? "dialog"          --> doFloat
    , className =? "download"        --> doFloat
    , className =? "error"           --> doFloat
    , className =? "Gimp"            --> doFloat
    , className =? "notification"    --> doFloat
    , className =? "pinentry-gtk-2"  --> doFloat
    , className =? "splash"          --> doFloat
    , className =? "toolbar"         --> doFloat
    , isFullscreen -->  doFullFloat
    ]

--
-- Auto-Start
--
myStartupHook :: X ()
myStartupHook = do
    spawnOnce "$HOME/.fehbg"
    spawnOnce "pactl set-sink-mute @DEFAULT_SINK@ 0"
    setWMName "LG3D"

--
-- Keys
--
myKeys :: [(String, X ())]
myKeys = [
        -- Windows Hotkeys
      ("M-c", kill1)

    , ("M-h", sendMessage Shrink)                -- Shrink horiz window width
    , ("M-l", sendMessage Expand)                -- Expand horiz window width
    , ("M-j", sendMessage MirrorShrink)          -- Shrink vert window width
    , ("M-k", sendMessage MirrorExpand)          -- Expand vert window width

      -- Master Hotkeys
    , ("M-<Return>", spawn (myTerminal))
    , ("M-p", spawn (myLauncher)) -- Dmenu
    , ("<Print>", unGrab *> spawn "maim -s -u | xclip -selection clipboard -t image/png -i && notify-send 'Imagem copiada'")
    , ("M-S-q", io exitSuccess)

      -- (Super + a) Applications
    , ("M-a t", spawn "thunar")
    , ("M-a b", spawn "librewolf")
    , ("M-a e", spawn "emacs")

      -- Toggle Bar
    , ("M-b", sendMessage ToggleStruts)

      -- Audio Controls
    , ("M-<KP_Subtract>", spawn (volumeLower))
    , ("M-<KP_Add>", spawn (volumeRaise))
    , ("M-<KP_Decimal>", spawn (volumeMute))
    , ("<XF86AudioLowerVolume>", spawn (volumeLower))
    , ("<XF86AudioRaiseVolume>", spawn (volumeRaise))
    , ("<XF86AudioMute>", spawn (volumeMute))

      -- Player Controls
    , ("M-<Up>", spawn "~/.local/bin/playerctlnotify")
    , ("M-<Down>", spawn "playerctl play-pause")
    , ("M-<Right>", spawn "playerctl next")
    , ("M-<Left>", spawn "playerctl previous")
    ]

myMouse (XConfig {XMonad.modMask = modm}) = M.fromList $

    [ ((modm, button1), (\w -> focus w >> mouseMoveWindow w
                                       >> windows W.shiftMaster))

    , ((modm, button2), (\w -> focus w >> windows W.shiftMaster))

    , ((modm, button3), (\w -> focus w >> Flex.mouseResizeWindow w))
    ]

--
-- Xmobar Config
--
myLogHook h = dynamicLogWithPP $ def
    {
      ppTitleSanitize = const ""
    , ppCurrent = xmobarColor "#88C0D0" "" . wrap "<<box type=Bottom width=2 mb=2 color=#88C0D0>" "</box>>"
    , ppOutput  = hPutStrLn h
    }

--
-- Main Settings
--
main :: IO ()
main = do
  xmproc0 <- spawnPipe "xmobar -x 0 ~/.xmobarrc"
  xmonad $ docks $ ewmh $ def {
      modMask            = mod4Mask
    , layoutHook         = myLayout
    , terminal           = myTerminal
    , normalBorderColor  = myNormalBorderColor
    , focusedBorderColor = myFocusedBorderColor
    , workspaces         = myWorkspaces
    , borderWidth        = myBorderWidth
    , manageHook         = myManageHook
    , startupHook        = myStartupHook
    , logHook            = myLogHook xmproc0
    , mouseBindings      = myMouse
    } `additionalKeysP` myKeys
