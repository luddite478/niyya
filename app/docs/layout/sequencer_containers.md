# Sequencer Body Container Structure

## Main Layout Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                    SampleGridWidget                         │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────┐ │
│  │              Consumer<SequencerState>                   │ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │  Container (margin: top:0, bottom:0)               │ │ │
│  │  │  ┌─────────────────────────────────────────────────┐ │ │ │
│  │  │  │  StackedCardsWidget (numCards: 4)              │ │ │ │
│  │  │  │  ┌─────────────────────────────────────────────┐ │ │ │ │
│  │  │  │  │  cardBuilder: (index, width, height, depth) │ │ │ │ │
│  │  │  │  │  ┌─────────────────────────────────────────┐ │ │ │ │ │ │
│  │  │  │  │  │  SizedBox (height + 100)               │ │ │ │ │ │
│  │  │  │  │  │  ┌─────────────────────────────────────┐ │ │ │ │ │ │ │
│  │  │  │  │  │  │  Stack (clipBehavior: Clip.none)    │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  ┌─────────────────────────────────┐ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  Positioned (top:37)            │ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  ┌─────────────────────────────┐ │ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  │  _buildMainCard()           │ │ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  │  ┌─────────────────────────┐ │ │ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  │  │  Padding (all:2)        │ │ │ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  │  │  ┌─────────────────────┐ │ │ │ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  │  │  │  Column             │ │ │ │ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  │  │  │  ├─ SizedBox(8)     │ │ │ │ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  │  │  │  └─ Expanded        │ │ │ │ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  │  │  │     └─ _buildGridContent() │ │ │ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  │  │  │        ┌──────────┐ │ │ │ │ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  │  │  │        │GestureDetector│ │ │ │ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  │  │  │        │  └─ ListView.builder │ │ │ │ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  │  │  │        │     ├─ _buildGridRow() │ │ │ │ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  │  │  │        │     └─ RepaintBoundary │ │ │ │ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  │  │  │        │        └─ _buildGridRowControls() │ │ │ │ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  │  │  │        └──────────┘ │ │ │ │ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  │  │  └─────────────────────┘ │ │ │ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  │  └─────────────────────────┘ │ │ │ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  │  └─────────────────────────────┘ │ │ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  └─────────────────────────────────┘ │ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  ┌─────────────────────────────────┐ │ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  │  Positioned (top:15)            │ │ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  │  ┌─────────────────────────────┐ │ │ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  │  │  _buildClickableTabLabel()  │ │ │ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  │  │  (L1, L2, L3, L4)           │ │ │ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  │  └─────────────────────────────┘ │ │ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  └─────────────────────────────────┘ │ │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  └─────────────────────────────────────┘ │ │ │ │ │ │ │ │
│  │  │  │  │  │  └─────────────────────────────────────────┘ │ │ │ │ │ │
│  │  │  │  │  └─────────────────────────────────────────────┘ │ │ │ │ │
│  │  │  │  └─────────────────────────────────────────────────┘ │ │ │ │
│  │  │  └─────────────────────────────────────────────────────┘ │ │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Grid Row Structure

```
┌─────────────────────────────────────────────────────────────┐
│  _buildGridRow() Container (padding: horizontal:0, vertical:2) │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  Row                                                     │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐       │ │
│  │  │ Expanded│ │ Expanded│ │ Expanded│ │ Expanded│       │ │
│  │  │┌───────┐│ │┌───────┐│ │┌───────┐│ │┌───────┐│       │ │
│  │  ││Container││ ││Container││ ││Container││ ││Container││       │ │
│  │  ││margin:2││ ││margin:2││ ││margin:2││ ││margin:2││       │ │
│  │  ││┌─────┐││ ││┌─────┐││ ││┌─────┐││ ││┌─────┐││       │ │
│  │  │││_build│││ │││_build│││ │││_build│││ │││_build│││       │ │
│  │  │││GridCell│││ │││GridCell│││ │││GridCell│││ │││GridCell│││       │ │
│  │  ││└─────┘││ ││└─────┘││ ││└─────┘││ ││└─────┘││       │ │
│  │  └┴───────┴┘ └┴───────┴┘ └┴───────┴┘ └┴───────┴┘       │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Control Buttons Structure

```
┌─────────────────────────────────────────────────────────────┐
│  RepaintBoundary                                            │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  Container (margin: left:16, right:16, bottom:60, top:4)│ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │  _buildGridRowControls() Container (height:30)      │ │ │
│  │  │  ┌─────────────────────────────────────────────────┐ │ │ │
│  │  │  │  Row                                             │ │ │ │
│  │  │  │  ┌─────────────┐ ┌─────────────┐               │ │ │ │ │
│  │  │  │  │   Expanded  │ │   Expanded  │               │ │ │ │ │ │
│  │  │  │  │ ┌─────────┐ │ │ ┌─────────┐ │               │ │ │ │ │ │
│  │  │  │  │ │_buildControlButton()│ │ │ │_buildControlButton()│ │               │ │ │ │ │ │ │
│  │  │  │  │ │  (remove) │ │ │ │  (add)   │ │               │ │ │ │ │ │ │
│  │  │  │  │ └─────────┘ │ │ └─────────┘ │               │ │ │ │ │ │ │
│  │  │  │  └─────────────┘ └─────────────┘               │ │ │ │ │ │
│  │  │  └─────────────────────────────────────────────────┘ │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Key Spacing Values

- **Main card padding**: `EdgeInsets.all(2)`
- **Tab space**: `SizedBox(height: 8)`
- **Grid row padding**: `EdgeInsets.symmetric(horizontal: 0, vertical: 2)`
- **Cell spacing**: `EdgeInsets.symmetric(horizontal: 2)`
- **Control buttons margin**: `EdgeInsets.symmetric(horizontal: 16)`
- **Control buttons container**: `EdgeInsets.only(left: 16, right: 16, bottom: 60, top: 4)`
- **StackedCards offset**: `Offset(0, -8)`
- **Card factors**: `width: 0.98, height: 0.98`

## Container Types

- **StackedCardsWidget**: Manages 4 layered cards with depth effect
- **ListView.builder**: Scrollable grid content with performance optimization
- **RepaintBoundary**: Isolates control buttons for better performance
- **Positioned**: Places tabs and main content precisely
- **Expanded**: Distributes grid cells evenly across row width 