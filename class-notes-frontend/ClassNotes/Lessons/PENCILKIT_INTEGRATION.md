# PencilKit Integration

This document describes the PencilKit integration in the Class Notes app for creating handwritten notes and drawings.

## Overview

PencilKit has been integrated to allow users to create handwritten notes and drawings within their lessons. This provides a natural way to sketch diagrams, write equations, or take visual notes during class.

## Components

### 1. PencilKitDrawingView
- **Location**: `Views/PencilKitDrawingView.swift`
- **Purpose**: UIViewRepresentable wrapper for PKCanvasView
- **Features**:
  - Supports both drawing and read-only modes
  - Manages tool picker visibility
  - Handles drawing input from Apple Pencil or finger

### 2. DrawingEditorView
- **Location**: `Views/DrawingEditorView.swift`
- **Purpose**: Full-featured drawing editor
- **Features**:
  - Create new drawings or edit existing ones
  - Background color selection
  - Save/cancel with unsaved changes warning
  - Share drawings as images
  - Clear canvas functionality

### 3. DrawingsGalleryView
- **Location**: `Views/DrawingsGalleryView.swift`
- **Purpose**: Gallery view for all drawings in a lesson
- **Features**:
  - Grid layout with thumbnails
  - Navigation to view/edit drawings
  - Empty state for lessons without drawings

### 4. DrawingCanvas Model
- **Location**: `Models/DrawingCanvas.swift`
- **Purpose**: SwiftData model for storing drawing data
- **Properties**:
  - Stores PencilKit drawing data
  - Thumbnail generation
  - Background color
  - Creation/modification dates
  - Lock status

## Usage

### Creating a New Drawing

1. From the Lesson Detail view, scroll to the Drawings section
2. Tap "Create Drawing" or the "+" button
3. Use the PencilKit tools to draw
4. Tap "Save" to save the drawing to the lesson

### Editing an Existing Drawing

1. Navigate to the drawing from the gallery or recent drawings
2. Tap "Edit" in the viewer
3. Make changes using PencilKit tools
4. Save changes

### Key Features

- **Tool Picker**: Access Apple's native drawing tools (pen, pencil, marker, etc.)
- **Background Colors**: Choose from preset background colors
- **Thumbnails**: Automatic thumbnail generation for gallery view
- **Share**: Export drawings as images
- **Responsive**: Works with Apple Pencil, finger, or mouse input

## Technical Implementation

The integration uses:
- `PencilKit` framework for drawing functionality
- `PKCanvasView` for the drawing surface
- `PKToolPicker` for drawing tools
- `PKDrawing` for storing drawing data
- SwiftData for persistence

## Future Enhancements

- Text recognition in drawings
- Shape recognition
- Drawing templates
- Collaborative drawing
- Export to PDF with drawings
- Drawing layers
- Custom color picker 