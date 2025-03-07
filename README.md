# Space Invaders Detector

This application detects Space Invader patterns in radar samples. By using pattern matching with customizable similarity thresholds, it can identify potential invaders even with noise and partial visibility.

## Features

- Detect multiple known Space Invader patterns in radar samples
- Adjust similarity threshold for detection sensitivity
- Handle partially visible invaders at radar edges
- Configurable via command-line options
- Filter detection by invader types
- Extensible design for adding new invader patterns

## Requirements

- Ruby 3.0.0 or higher
- Bundler

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/megarami/space-invaders
   cd space_invaders
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

## Usage

Run the detector with a radar sample file:

```bash
ruby run_detector.rb radar_1.txt
```

### Command Line Options

```
Usage: run_detector.rb [options] RADAR_FILE
    -s, --similarity FLOAT           Minimum similarity threshold (default: 0.7)
    -i, --invaders LIST              Invader types to detect: large, small, or both (default: large,small)
    -h, --help                       Show this help message
```

### Examples

Detect all invaders with default settings:
```bash
ruby run_detector.rb samples/radar1.txt
```

Detect with a lower similarity threshold (more sensitive):
```bash
ruby run_detector.rb -s 0.6 samples/radar_1.txt
```

Detect only small invaders:
```bash
ruby run_detector.rb -i small samples/radar_1.txt
```

## Known Invader Patterns

### Large Invader
```
--o-----o--
---o---o---
--ooooooo--
-oo-ooo-oo-
ooooooooooo
o-ooooooo-o
o-o-----o-o
---oo-oo---
```

### Small Invader
```
---oo---
--oooo--
-oooooo-
oo-oo-oo
oooooooo
--o--o--
-o-oo-o-
o-o--o-o
```

## How It Works

1. The application loads the radar sample and known invader patterns
2. For each invader, it scans the radar by sliding a window across all possible positions
3. At each position, it calculates the similarity between the invader pattern and the radar data
4. If the similarity exceeds the threshold and enough of the pattern is visible, it's considered a match
5. Duplicate matches (same invader in very close positions) are filtered out
6. Results are displayed, showing each match with its position and similarity score

## Adding New Invader Patterns

To add a new invader pattern:

Create a new class in `lib/space_invaders/` (e.g., `medium_invader.rb`):

```ruby
# frozen_string_literal: true

module SpaceInvaders
  class MediumInvader < Invader
    initialize_pattern(
      <<~PATTERN
        # Your pattern here
      PATTERN
    )
  end
end
```

## Running Tests

Run the test suite with:

```bash
bundle exec rspec
```

To check code quality:

```bash
bundle exec rubocop
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.