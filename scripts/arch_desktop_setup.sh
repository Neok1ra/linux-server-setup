#!/bin/bash

# Arch Linux Desktop Environment Setup Script
# This script sets up either Hyprland or Sway desktop environments

# Check if running on Arch Linux
if ! grep -q "Arch Linux" /etc/os-release 2>/dev/null; then
    echo "This script is intended for Arch Linux only."
    exit 1
fi

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Function to install Hyprland
install_hyprland() {
    echo "Installing Hyprland desktop environment..."
    
    # Install Hyprland and related packages
    if ! pacman -S --noconfirm hyprland kitty waybar rofi dunst polkit-kde xdg-desktop-portal-hyprland qt5-wayland qt6-wayland; then
        echo "WARNING: Failed to install Hyprland packages"
    fi
    
    # Install additional tools
    if ! pacman -S --noconfirm firefox code thunar thunar-archive-plugin file-roller alacritty git wget curl vim nano htop; then
        echo "WARNING: Failed to install additional tools"
    fi
    
    # Create basic configuration directories
    sudo -u $SUDO_USER mkdir -p /home/$SUDO_USER/.config/hypr
    sudo -u $SUDO_USER mkdir -p /home/$SUDO_USER/.config/waybar
    sudo -u $SUDO_USER mkdir -p /home/$SUDO_USER/.config/rofi
    
    # Create a basic Hyprland configuration
    cat > /home/$SUDO_USER/.config/hypr/hyprland.conf << EOF
# See https://wiki.hyprland.org/Configuring/ for more configuration options

# Monitor configuration
monitor=,preferred,auto,1

# Execute your favorite apps at launch
exec-once = waybar
exec-once = firefox

# Example binds (see https://wiki.hyprland.org/Configuring/Binds/ for more)
bind = \$mod, Return, exec, kitty
bind = \$mod, Q, killactive, 
bind = \$mod, E, exec, thunar
bind = \$mod, V, togglefloating, 
bind = \$mod, R, exec, rofi -show drun
bind = \$mod, P, pseudo, # dwindle
bind = \$mod, J, togglesplit, # dwindle

# Move focus with mod + arrow keys
bind = \$mod, left, movefocus, l
bind = \$mod, right, movefocus, r
bind = \$mod, up, movefocus, u
bind = \$mod, down, movefocus, d

# Switch workspaces with mod + [0-9]
bind = \$mod, 1, workspace, 1
bind = \$mod, 2, workspace, 2
bind = \$mod, 3, workspace, 3
bind = \$mod, 4, workspace, 4
bind = \$mod, 5, workspace, 5
bind = \$mod, 6, workspace, 6
bind = \$mod, 7, workspace, 7
bind = \$mod, 8, workspace, 8
bind = \$mod, 9, workspace, 9
bind = \$mod, 0, workspace, 10

# Move active window to a workspace with mod + shift + [0-9]
bind = \$mod SHIFT, 1, movetoworkspace, 1
bind = \$mod SHIFT, 2, movetoworkspace, 2
bind = \$mod SHIFT, 3, movetoworkspace, 3
bind = \$mod SHIFT, 4, movetoworkspace, 4
bind = \$mod SHIFT, 5, movetoworkspace, 5
bind = \$mod SHIFT, 6, movetoworkspace, 6
bind = \$mod SHIFT, 7, movetoworkspace, 7
bind = \$mod SHIFT, 8, movetoworkspace, 8
bind = \$mod SHIFT, 9, movetoworkspace, 9
bind = \$mod SHIFT, 0, movetoworkspace, 10

# Scroll through existing workspaces with mod + scroll
bind = \$mod, mouse_down, workspace, e+1
bind = \$mod, mouse_up, workspace, e-1

# Window resize and move
bind = \$mod, S, togglespecialworkspace, 
bind = \$mod SHIFT, S, movetoworkspace, special

# Resizing and moving windows with mod + RMB/LMB
bindm = \$mod, mouse:273, resizewindow
bindm = \$mod, mouse:272, movewindow

# Exit Hyprland
bind = \$mod SHIFT, Q, exit, 

# Reload configuration
bind = \$mod SHIFT, R, reload, 

# Toggle fullscreen
bind = \$mod SHIFT, F, fullscreen, 0

# Special workspace (scratchpad)
bind = \$mod, S, togglespecialworkspace, 
bind = \$mod SHIFT, S, movetoworkspace, special

# Groups
bind = \$mod, G, togglegroup, 
bind = \$mod, Tab, changegroupactive, f

# Layout toggles
bind = \$mod, T, togglefloating, 
bind = \$mod, F, fullscreen, 0

# Set mod key to Super (Windows key)
\$mod = SUPER
EOF

    # Set proper ownership
    chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.config/hypr
    
    echo "Hyprland installation completed!"
    echo "To start Hyprland, run 'exec hyprland' from a TTY"
}

# Function to install Sway
install_sway() {
    echo "Installing Sway desktop environment..."
    
    # Install Sway and related packages
    if ! pacman -S --noconfirm sway swaylock swayidle waybar rofi dunst polkit-kde xdg-desktop-portal-wlr qt5-wayland qt6-wayland; then
        echo "WARNING: Failed to install Sway packages"
    fi
    
    # Install additional tools
    if ! pacman -S --noconfirm firefox code thunar thunar-archive-plugin file-roller alacritty git wget curl vim nano htop; then
        echo "WARNING: Failed to install additional tools"
    fi
    
    # Create basic configuration directories
    sudo -u $SUDO_USER mkdir -p /home/$SUDO_USER/.config/sway
    sudo -u $SUDO_USER mkdir -p /home/$SUDO_USER/.config/waybar
    sudo -u $SUDO_USER mkdir -p /home/$SUDO_USER/.config/rofi
    
    # Create a basic Sway configuration
    cat > /home/$SUDO_USER/.config/sway/config << EOF
# Default config for sway
#
# Copy this to ~/.config/sway/config if you wish to use it as your config.
# You may want to copy the contents of the 'config' file to your own config
# as it has a lot of good examples of how to use Sway's features.

# Variables
set \$mod Mod4
set \$alt Mod1
set \$term alacritty

# Your preferred terminal emulator
set \$terminal \$term
set \$menu dmenu_path | dmenu | \$terminal -e bash -c "exec \\\$(0) || { read -rsp Press any key to continue...; }"

# Your preferred application launcher
set \$menu dmenu_run

# Output configuration
# Example for one monitor:
# output HDMI-A-1 resolution 1920x1080 position 0,0

# Wallpaper
# exec_always feh --bg-scale /path/to/your/wallpaper.jpg

# Hide the bar
# bar mode dock
# bar mode hide

# Status bar colors
# bar {
#     colors {
#         statusline #ffffff
#         background #323232
#         inactive_workspace #32323200 #32323200 #5c5c5c
#     }
# }

# Basic border colors
client.focused          #000000 #000000 #ffffff #000000
client.focused_inactive #333333 #5f676a #ffffff #5f676a
client.unfocused        #333333 #222222 #888888 #222222
client.urgent           #2f343a #900000 #ffffff #900000
client.placeholder      #000000 #0c0c0c #ffffff #000000

client.background       #ffffff

# Font for window titles
font pango:monospace 10

# Key bindings
# Start a terminal
bindsym \$mod+Return exec \$terminal

# Kill focused window
bindsym \$mod+Shift+q kill

# Start your launcher
bindsym \$mod+d exec \$menu

# Drag floating windows by holding down \$mod and left mouse button.
# Resize them by holding down \$mod and right mouse button.
floating_modifier \$mod

# Reload the configuration file
bindsym \$mod+Shift+c reload

# Exit sway (logs you out of your Wayland session)
bindsym \$mod+Shift+e exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -B 'Yes, exit sway' 'swaymsg exit'

# Moving around:
# Move your focus around
bindsym \$mod+j focus left
bindsym \$mod+k focus down
bindsym \$mod+l focus up
bindsym \$mod+semicolon focus right

# Move the focused window with the same, but add Shift
bindsym \$mod+Shift+j move left
bindsym \$mod+Shift+k move down
bindsym \$mod+Shift+l move up
bindsym \$mod+Shift+semicolon move right

# Workspaces:
# Switch to workspace
bindsym \$mod+1 workspace number 1
bindsym \$mod+2 workspace number 2
bindsym \$mod+3 workspace number 3
bindsym \$mod+4 workspace number 4
bindsym \$mod+5 workspace number 5
bindsym \$mod+6 workspace number 6
bindsym \$mod+7 workspace number 7
bindsym \$mod+8 workspace number 8
bindsym \$mod+9 workspace number 9
bindsym \$mod+0 workspace number 10

# Move focused container to workspace
bindsym \$mod+Shift+1 move container to workspace number 1
bindsym \$mod+Shift+2 move container to workspace number 2
bindsym \$mod+Shift+3 move container to workspace number 3
bindsym \$mod+Shift+4 move container to workspace number 4
bindsym \$mod+Shift+5 move container to workspace number 5
bindsym \$mod+Shift+6 move container to workspace number 6
bindsym \$mod+Shift+7 move container to workspace number 7
bindsym \$mod+Shift+8 move container to workspace number 8
bindsym \$mod+Shift+9 move container to workspace number 9
bindsym \$mod+Shift+0 move container to workspace number 10

# Layout stuff:
# You can "split" the current object of your focus with
# \$mod+b or \$mod+v, for horizontal and vertical splits
# respectively.
bindsym \$mod+b splith
bindsym \$mod+v splitv

# Toggle between different layouts
bindsym \$mod+s layout stacking
bindsym \$mod+w layout tabbed
bindsym \$mod+e layout toggle split

# Make the current focus fullscreen
bindsym \$mod+f fullscreen

# Toggle the current focus between tiling and floating mode
bindsym \$mod+Shift+space floating toggle

# Swap focus between the tiling area and the floating area
bindsym \$mod+space focus mode_toggle

# Move focus to the parent container
bindsym \$mod+a focus parent

# Scratchpad:
# Move the currently focused window to the scratchpad
bindsym \$mod+Shift+minus move scratchpad

# Show the next scratchpad window or hide the focused scratchpad window
bindsym \$mod+minus scratchpad show

# Resizing containers
mode "resize" {
    # Left will shrink the containers width
    # Right will grow the containers width
    bindsym j resize shrink width 10px
    bindsym l resize grow width 10px

    # Up will shrink the containers height
    # Down will grow the containers height
    bindsym k resize shrink height 10px
    bindsym semicolon resize grow height 10px

    # Return to default mode
    bindsym Return mode "default"
    bindsym Escape mode "default"
}

bindsym \$mod+r mode "resize"

# Start applications
exec_always --no-startup-id waybar
exec_always --no-startup-id firefox
EOF

    # Set proper ownership
    chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.config/sway
    
    echo "Sway installation completed!"
    echo "To start Sway, run 'exec sway' from a TTY"
}

# Main script
echo "Arch Linux Desktop Environment Setup"
echo "===================================="
echo "1) Install Hyprland (Modern Wayland compositor)"
echo "2) Install Sway (i3-compatible Wayland compositor)"
echo "3) Exit"

read -p "Enter your choice (1-3): " choice

case $choice in
    1)
        install_hyprland
        ;;
    2)
        install_sway
        ;;
    3)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid choice. Exiting..."
        exit 1
        ;;
esac

echo ""
echo "Installation completed successfully!"
echo "Please reboot your system and start the desktop environment from a TTY."