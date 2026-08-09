FEATURE NAME
SEEKER NAVIGATION

SCRIPT VERSION: V1
STATUS: Approved Specification

============================================================
NAVIGATION IMPLEMENTATION
============================================================

------------------------------------------------------------
COMPONENT ARCHITECTURE
------------------------------------------------------------

Navigation uses one reusable Floating Glass Navigation
component.

The navigation transforms between states rather than
replacing components.

------------------------------------------------------------
NAVIGATION STATES
------------------------------------------------------------

STATE 1 — MAIN NAVIGATION
Tabs:
• Browse
• Connections
• Guardian
• Profile

STATE 2 — CONNECTIONS NAVIGATION
The Connections page replaces the standard navigation with
a Connections Navigation.

Left Side:
• Floating circular Back button.
• Uses the same glass design language as the Bell Icon.
• Returns to the Main Navigation.

Right Side:
Glass Navigation containing:
• Last 5 Declined
• Review
• Considerations
• Incoming Considerations
• Matches
Icons only. No text.

------------------------------------------------------------
COMPONENT INHERITANCE RULES
------------------------------------------------------------

The Main Navigation and Connections Navigation are two
states of the same navigation component.

Connections Navigation inherits every visual property
from the Main Navigation.

Both always share identical:
• Width
• Height
• Corner Radius
• Glass Effect
• Blur
• Border
• Shadow
• Padding
• Icon Spacing

Only these change between states:
• Navigation icons
• Navigation actions

------------------------------------------------------------
NAVIGATION SIZE
------------------------------------------------------------

Default:
Slightly larger than the previous implementation while
maintaining the same proportions and floating appearance.

Pressed:
Both navigation states expand using identical:
• Dimensions
• Scaling
• Timing
• Easing

Neither navigation should ever appear larger or smaller
than the other.

------------------------------------------------------------
NAVIGATION MOTION
------------------------------------------------------------

Reference:
• Uploaded Instagram navigation video.
• Uploaded ZYRA navigation video.

Maintain the approved ZYRA visual design.
Improve only the animation quality.

Requirements:
• Continuous movement
• No snapping
• No jumping
• No lag
• Active indicator glides smoothly
• Icons animate together with the indicator

Navigation should feel comparable to Instagram while
preserving the ZYRA visual identity.

------------------------------------------------------------
PRESS ANIMATION
------------------------------------------------------------

Applies to:
• Main Navigation
• Connections Navigation
• Floating Back Button

Behaviour:
• Slight scale down on press.
• Smooth return to normal size.
• Identical timing and easing across every navigation
  component.

------------------------------------------------------------
TOP RIGHT BUTTONS
------------------------------------------------------------

Displayed on:
• Browse
• Connections
• Guardian
• Profile

Production UI:
[ Bell ]

The Bell Icon is part of the production interface and
is always visible.

Developer Mode adds:
[ Back ] [ Home ]

Result in Developer Mode:
[ Back ] [ Home ] [ Bell ]

Developer Mode injects only the Back and Home buttons.
The Bell remains part of the production interface.

All three buttons share identical:
• Glass Effect
• Blur
• Border
• Shadow
• Size
• Shape
• Hover Animation
• Press Animation
• Spacing
• Vertical Alignment

------------------------------------------------------------
PROFILE NAVIGATION ICON
------------------------------------------------------------

• Use a universal profile silhouette icon.
• Do not display the user's uploaded profile image as
  the navigation icon.

------------------------------------------------------------
DESIGN GOAL
------------------------------------------------------------

Navigation should feel like one living component
transforming between navigation modes.

The user should never perceive separate navigation bars —
only one navigation component changing state.

Motion quality should closely match Instagram while
preserving the approved ZYRA visual language.
