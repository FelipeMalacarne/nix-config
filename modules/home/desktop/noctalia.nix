# modules/home/desktop/noctalia.nix
#
# Maps the active colorScheme (base16) to Noctalia color keys (m-prefixed camelCase).
# base16 → Catppuccin Mocha reference:
#   base00=base  base02=surface0  base03=surface1  base04=surface2
#   base05=text  base08=red       base0B=green     base0D=blue  base0E=mauve
#
# To switch themes: set `colorScheme` in the host file.
{
  inputs,
  pkgs,
  config,
  ...
}:
let
  p = config.colorScheme.palette;
in
{
  imports = [ inputs.noctalia.homeModules.default ];

  home.packages = with pkgs; [
    # screnshot plugin
    grim
    imagemagick
    swappy
    tesseract
    xdg-utils
    jq
    wf-recorder
  ];

  programs.noctalia-shell = {
    enable = true;

    colors = {
      mSurface = "#${p.base01}";
      mSurfaceVariant = "#${p.base02}";
      mPrimary = "#${p.base0E}";
      mOnPrimary = "#${p.base00}";
      mSecondary = "#${p.base0D}";
      mOnSecondary = "#${p.base00}";
      mTertiary = "#${p.base0B}";
      mOnTertiary = "#${p.base00}";
      mError = "#${p.base08}";
      mOnError = "#${p.base00}";
      mOnSurface = "#${p.base05}";
      mOnSurfaceVariant = "#${p.base04}";
      mOutline = "#${p.base03}";
      mHover = "#${p.base02}";
      mOnHover = "#${p.base05}";
      mShadow = "#000000";

    };

    settings = {
      bar = {
        barType = "simple";
        position = "top";
        monitors = [ ];
        density = "default";
        showOutline = false;
        showCapsule = true;
        capsuleOpacity = 1;
        capsuleColorKey = "none";
        widgetSpacing = 6;
        contentPadding = 2;
        fontScale = 1;
        enableExclusionZoneInset = true;
        backgroundOpacity = 0.93;
        useSeparateOpacity = false;
        marginVertical = 4;
        marginHorizontal = 4;
        frameThickness = 8;
        frameRadius = 12;
        outerCorners = true;
        hideOnOverview = false;
        displayMode = "always_visible";
        autoHideDelay = 500;
        autoShowDelay = 150;
        showOnWorkspaceSwitch = true;
        widgets = {
          left = [
            {
              colorizeSystemIcon = "none";
              colorizeSystemText = "none";
              customIconPath = "";
              enableColorization = false;
              icon = "rocket";
              iconColor = "none";
              id = "Launcher";
              useDistroLogo = false;
            }
            {
              characterCount = 2;
              colorizeIcons = false;
              emptyColor = "secondary";
              enableScrollWheel = true;
              focusedColor = "primary";
              followFocusedScreen = false;
              fontWeight = "bold";
              groupedBorderOpacity = 1;
              hideUnoccupied = false;
              iconScale = 0.8;
              id = "Workspace";
              labelMode = "index";
              occupiedColor = "secondary";
              pillSize = 0.6;
              showApplications = false;
              showApplicationsHover = false;
              showBadge = true;
              showLabelsOnlyWhenOccupied = true;
              unfocusedIconsOpacity = 1;
            }
            {
              colorizeIcons = false;
              hideMode = "hidden";
              id = "ActiveWindow";
              maxWidth = 145;
              scrollingMode = "hover";
              showIcon = true;
              showText = true;
              textColor = "none";
              useFixedWidth = false;
            }
            {
              compactMode = false;
              hideMode = "hidden";
              hideWhenIdle = false;
              id = "MediaMini";
              maxWidth = 145;
              panelShowAlbumArt = true;
              scrollingMode = "hover";
              showAlbumArt = true;
              showArtistFirst = true;
              showProgressRing = true;
              showVisualizer = false;
              textColor = "none";
              useFixedWidth = false;
              visualizerType = "linear";
            }
          ];
          center = [
            {
              clockColor = "none";
              customFont = "";
              formatHorizontal = "HH:mm ddd, MMM dd";
              formatVertical = "HH mm - dd MM";
              id = "Clock";
              tooltipFormat = "HH:mm ddd, MMM dd";
              useCustomFont = false;
            }
            {
              compactMode = true;
              diskPath = "/";
              iconColor = "none";
              id = "SystemMonitor";
              showCpuCores = false;
              showCpuFreq = false;
              showCpuTemp = true;
              showCpuUsage = true;
              showDiskAvailable = false;
              showDiskUsage = false;
              showDiskUsageAsPercent = false;
              showGpuTemp = false;
              showLoadAverage = false;
              showMemoryAsPercent = false;
              showMemoryUsage = true;
              showNetworkStats = false;
              showSwapUsage = false;
              textColor = "none";
              useMonospaceFont = true;
              usePadding = false;
            }
          ];
          right = [
            {
              blacklist = [ ];
              chevronColor = "none";
              colorizeIcons = false;
              drawerEnabled = true;
              hidePassive = false;
              id = "Tray";
              pinned = [ ];
            }
            {
              defaultSettings = { };
              id = "plugin:kde-connect";
            }
            {
              id = "plugin:tailscale";
              defaultSettings = {
                compactMode = false;
                defaultPeerAction = "copy-ip";
                hideDisconnected = false;
                hideMullvadExitNodes = true;
                pingCount = 5;
                refreshInterval = 5000;
                showIpAddress = true;
                showPeerCount = true;
                sshUsername = "";
                taildropDownloadDir = "~/Downloads";
                taildropEnabled = true;
                taildropReceiveMode = "operator";
                terminalCommand = "";
              };
            }
            {
              defaultSettings = {
                enableCross = true;
                enableWindowsSelection = true;
                screenshotEditor = "swappy";
              };
              id = "plugin:screen-shot-and-record";
            }
            {
              hideWhenZero = false;
              hideWhenZeroUnread = false;
              iconColor = "none";
              id = "NotificationHistory";
              showUnreadBadge = true;
              unreadBadgeColor = "primary";
            }
            {
              deviceNativePath = "__default__";
              displayMode = "graphic-clean";
              hideIfIdle = false;
              hideIfNotDetected = true;
              id = "Battery";
              showNoctaliaPerformance = false;
              showPowerProfiles = false;
            }
            {
              displayMode = "onhover";
              iconColor = "none";
              id = "Volume";
              middleClickCommand = "pwvucontrol || pavucontrol";
              textColor = "none";
            }
            {
              colorizeDistroLogo = false;
              colorizeSystemIcon = "none";
              colorizeSystemText = "none";
              customIconPath = "";
              enableColorization = false;
              icon = "noctalia";
              id = "ControlCenter";
              useDistroLogo = false;
            }
          ];
        };
        mouseWheelAction = "none";
        reverseScroll = false;
        mouseWheelWrap = true;
        middleClickAction = "none";
        middleClickFollowMouse = false;
        middleClickCommand = "";
        rightClickAction = "controlCenter";
        rightClickFollowMouse = true;
        rightClickCommand = "";
        screenOverrides = [ ];
      };
      wallpaper = {
        enable = true;
      };
    };
  };

}
