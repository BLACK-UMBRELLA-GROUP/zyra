---
id: DOC-ZYRA-0006
type: SPEC
status: CURRENT
feature: APP: BROWSE
purpose: Browse / Script — Script V1
links: []
owner: ZYRA chat
---

FEATURE NAME
BROWSE

SCRIPT VERSION: V1
STATUS: Approved Specification
SOURCE: Master Script Part 3

============================================================
FULL SCREEN PROFILE EXPERIENCE
============================================================

The Browse experience is built around a photo-first
philosophy.

Requirements:
• Remove all card containers.
• Remove framed profile cards.
• Remove visible boxes around profile images.
• The profile photo becomes the primary screen background.
• Full Width
• Full Height
• Edge-to-Edge
• No Card Border
• No Container
• No Shadow Around Image

The photograph occupies the entire screen behind the
interface.

============================================================
FLOATING USER INTERFACE
============================================================

All interface elements float above the profile image.
Do not create separate containers.
The UI should feel layered over the image.

Floating elements:
• Notification Bell
• Developer Buttons
• Universal Toggle
• Action Bar
• Decision Strip
• Bottom Navigation
• Profile Information

All appear as floating overlays.

============================================================
UNIVERSAL PAGE HEADER
============================================================

Remove every page-specific text from the top of profile
photos.

Examples to remove:
• London
• Manchester
• Birmingham
• Any location label

Only approved floating controls occupy this area.

============================================================
PROFILE INFORMATION
============================================================

Always display:
• Name
• Age
• Location

Position: Bottom Left.

Maintain consistent spacing above:
• Universal Toggle
• Action Bar
• Bottom Navigation

Never overlap navigation controls.

============================================================
PHOTO CAROUSEL
============================================================

Support:
• Swipe Left / Right
• Tap Left / Right

Photo transitions should feel instant.

============================================================
PHOTO LOOP
============================================================

Final photo → Next tap → Return to Photo 1.
The gallery loops forever.

============================================================
PHOTO INDICATORS
============================================================

Display indicators at the top.

Rules:
• All indicators remain the same size.
• Active indicator is white with higher opacity.
• Inactive indicators use lower opacity.
• No scaling animation.

============================================================
DEMO PROFILE SYSTEM
============================================================

During development, Browse is automatically populated using:
• Female Portrait 1–10
• Male Portrait 1–10

Each portrait set represents one person.

------------------------------------------------------------
PROFILE CREATION
------------------------------------------------------------

One portrait set creates one Demo Profile.

Example:
Female Portrait 1 → Female Demo Profile 1
Continue through Female Demo Profile 10.
Repeat for Male Portrait 1–10.

------------------------------------------------------------
PHOTO USAGE
------------------------------------------------------------

Each Demo Profile uses:
• First image → Profile Photo
• Remaining images → Gallery Photos

Requirements:
• Preserve image quality
• No aggressive cropping
• Gallery carousel supported

------------------------------------------------------------
PROFILE VISIBILITY
------------------------------------------------------------

• Male Seekers see Female Demo Profiles only.
• Female Seekers see Male Demo Profiles only.
• Never display same-gender profiles.

------------------------------------------------------------
BROWSE PAGE DATA
------------------------------------------------------------

Automatically populate:
• First Name
• Age
• City

Example names:
• Aisha — 24 — London
• Maryam — 27 — Birmingham
• Fatimah — 22 — Manchester
• Ahmed — 26 — London
• Yusuf — 29 — Leicester
• Ibrahim — 24 — Birmingham

------------------------------------------------------------
DEMO PROFILE TAG
------------------------------------------------------------

Every generated profile contains:
isDemoProfile = true

------------------------------------------------------------
FUTURE PROFILE BEHAVIOUR
------------------------------------------------------------

Display:
• Real Users
• Demo Profiles

Admin can:
• Disable Demo Profiles
• Remove Demo Profiles
• Replace Demo Profiles

No architectural changes required.

------------------------------------------------------------
CURRENT IMPLEMENTATION
------------------------------------------------------------

Demo Profiles currently apply only to:
• Male Seeker
• Female Seeker

Ignore Guardian accounts.

============================================================
PROFILE IMAGE FAILSAFE
============================================================

If a profile image fails to load:
Display a placeholder profile image.

Never display:
• Broken image icon
• Missing image icon
• Question mark image

============================================================
DESIGN GOAL
============================================================

The Browse experience should feel comparable to:
• Tinder
• Bumble
• Instagram Stories

• Large immersive photography.
• Minimal interface.
• Floating premium controls.
• Photos remain the primary focus throughout.
• The user should feel they are interacting directly
  with photographs.
• Navigation and controls remain secondary.
• The interface communicates state through elegant motion
  rather than notifications.

Experience goals:
• Premium
• Fast
• Fluid
• Minimal
• Native to iOS
