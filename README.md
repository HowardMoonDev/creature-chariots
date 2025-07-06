# Creature Chariots: The Skyborne Gauntlet

A fantasy racing game built in Godot 4, inspired by Star Wars Episode I Racer with creature management mechanics.

## Project Structure

```
creaturechariots/
├── scenes/
│   ├── chariots/          # Chariot vehicle scenes
│   ├── tracks/            # Race track scenes
│   └── ui/                # User interface scenes
├── scripts/               # GDScript files
├── assets/
│   ├── models/            # 3D models
│   ├── textures/          # Texture files
│   └── sounds/            # Audio files
└── resources/             # Godot resources
```

## Current Implementation Status

### ✅ Completed Features

1. **Project Structure**: Organized folder hierarchy for scalable development
2. **Basic Chariot Movement**: 
   - Forward/backward acceleration with WASD or arrow keys
   - Left/right steering with realistic speed-based handling
   - Boost system with energy consumption and regeneration
   - Air control for jumps and gaps
   - Damage/durability system affecting performance

3. **Simple Track Creation**:
   - Basic oval test track with curves and straights
   - Track barriers and boundaries
   - Checkpoint system for lap counting
   - Player spawn point

4. **Camera System**:
   - Third-person racing camera built into the chariot
   - Camera automatically follows as child of chariot
   - Look-ahead based on velocity for dynamic framing
   - Camera shake system for impacts
   - Simplified architecture with camera as chariot child

5. **Core Racing Mechanics**:
   - Real-time HUD showing speed, boost energy, and hull integrity
   - Lap and position tracking
   - Input mapping for keyboard controls
   - Physics-based movement with gravity

6. **Visual Creature System**:
   - Two creature blocks positioned in front of chariot
   - Creatures appear as if pulling the chariot (like pod racing)
   - Placeholder visual representation for future creature models

### 🎮 Controls

- **W / Up Arrow**: Accelerate
- **S / Down Arrow**: Decelerate/Reverse
- **A / Left Arrow**: Steer Left
- **D / Right Arrow**: Steer Right
- **Shift**: Boost (consumes energy)
- **Enter**: Start Race
- **Escape**: Restart Race

### 🚀 Getting Started

1. Open the project in Godot 4.4+
2. Run the main scene (`main.tscn`)
3. Use WASD keys to control the chariot
4. Hold Shift to boost (watch your energy!)
5. Try to complete laps around the test track

### 📋 Next Development Steps

1. **Enhanced Track Design**:
   - Add environmental hazards (wind gusts, energy vents)
   - Create multiple track environments (Cloudspire, Mire, Crystal Canyon)
   - Implement proper lap counting with checkpoint validation

2. **Creature System**:
   - Create basic creature models (Sky-Serpent, Gale-Hound, Stone-Beast)
   - Implement creature attachment to chariots
   - Add creature-specific visual effects for gliding

3. **AI Opponents**:
   - Basic waypoint-following AI racers
   - Varying difficulty levels and behaviors

4. **Sky Sanctuary**:
   - Creature management hub area
   - Hatching, training, and fusion mechanics
   - Peaceful environment for creature interaction

5. **Enhanced Visuals**:
   - Particle effects for boost, damage, and environmental elements
   - Improved 3D models and textures
   - Dynamic lighting and atmospheric effects

## Technical Notes

- Built with Godot 4.4 using GDScript
- Uses CharacterBody3D for arcade-style physics
- Modular scene architecture for easy expansion
- Signal-based communication between systems

## Architecture Decisions

- **CharacterBody3D vs RigidBody3D**: Chose CharacterBody3D for more predictable arcade racing physics
- **Scene Composition**: Each major component (chariot, track, HUD) is a separate scene for modularity
- **Signal System**: Used Godot signals for loose coupling between chariot, camera, and HUD
- **Input Mapping**: Programmatic input map setup for consistent controls across different keyboards
