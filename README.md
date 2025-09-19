# Patriot Race Results App

A Flutter application for displaying race results for the Patriot event with real-time updates from Supabase.

## Features

- **Overall Rankings**: Display all runners with their rankings
- **Gender-based Rankings**: Separate views for Male and Female runners
- **Category Rankings**: 6 different category tables (Overall, Male, Female, Category 1, Category 2, Category 3)
- **Sortable Columns**: All tables support sorting by rank, bib number, name, and time
- **Real-time Updates**: Live updates from Supabase database
- **Modern UI**: Beautiful, responsive design with Material 3

## Setup Instructions

### 1. Flutter Setup
```bash
flutter pub get
```

### 2. Supabase Setup

1. Create a new Supabase project at [supabase.com](https://supabase.com)
2. Run the SQL script in `supabase_setup.sql` in your Supabase SQL editor
3. Get your project URL and anon key from Supabase dashboard
4. Update the configuration in `lib/main.dart`:
   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL',
     anonKey: 'YOUR_SUPABASE_ANON_KEY',
   );
   ```

### 3. Database Schema

The app uses a single `runners` table with the following structure:
- `id`: UUID primary key
- `name`: Runner's name
- `bib`: Bib number (unique)
- `gender`: Male or Female
- `category`: Race category
- `start_time`: Start time (cp0)
- `finish_time`: Finish time (cp9)
- `total_time`: Total race time in seconds

### 4. Running the App

```bash
flutter run
```

## App Structure

- `lib/main.dart`: App entry point with Supabase initialization
- `lib/models/`: Data models for Runner and RaceCategory
- `lib/screens/`: UI screens (HomeScreen, ResultScreen)
- `lib/services/`: Supabase service for data operations
- `lib/config/`: Configuration files

## Features Overview

### Home Screen
- Grid layout with 6 category cards
- Each card represents a different result view
- Modern card design with icons and gradients

### Result Screen
- Sortable data table with all runner information
- Summary statistics (Total, Finished, DNF)
- Real-time refresh capability
- Responsive design for different screen sizes

### Data Table Columns
- **Rank**: Position based on finish time
- **Bib**: Runner's bib number
- **Name**: Runner's name
- **Gender**: Male/Female with icons
- **Time Result**: Formatted finish time or DNF

## Customization

### Adding New Categories
1. Update `RaceCategory` enum in `lib/models/race_category.dart`
2. Add corresponding case in `ResultScreen._loadRunners()`
3. Update the home screen grid if needed

### Styling
- Colors and themes are defined in `main.dart`
- Card designs and gradients can be customized in individual screens
- Material 3 design system is used throughout

## Real-time Updates

The app supports real-time updates through Supabase's real-time subscriptions. When data changes in the database, the UI will automatically refresh to show the latest results.

## Dependencies

- `flutter`: Flutter SDK
- `supabase_flutter`: Supabase integration
- `data_table_2`: Enhanced data table with sorting
- `intl`: Internationalization support

## License

This project is created for the Patriot race event.
