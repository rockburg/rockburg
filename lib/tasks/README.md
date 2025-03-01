# Rockburg Rake Tasks

This directory contains rake tasks for various maintenance and development operations.

## Development Tasks

### Reset Game State

The `dev:reset` task resets the entire game state to a fresh season. This is useful for development and testing purposes.

```bash
# Reset with default number of artists (50)
bundle exec rake dev:reset

# Reset with custom number of artists
ARTIST_COUNT=100 bundle exec rake dev:reset
```

This task will:
1. Deactivate all existing seasons
2. Reset all managers to their initial state (Level 1, $1000 budget, 0 XP, 0 skill points)
3. Remove all existing artists
4. Create a new active season
5. Generate new artists in the background

### Regenerate Artists

The `dev:regenerate_artists` task allows you to regenerate artists without resetting the entire game state.

```bash
# Regenerate default number of artists (50)
bundle exec rake dev:regenerate_artists

# Regenerate custom number of artists
COUNT=100 bundle exec rake dev:regenerate_artists
```

## Admin Tasks

### Manage Admin Users

```bash
# Make a user an admin
bundle exec rake admin:create[user@example.com]

# List all admin users
bundle exec rake admin:list
```

## Artist Tasks

### Regenerate Signing Costs

```bash
# Regenerate signing costs for all artists
bundle exec rake artists:regenerate_signing_costs
``` 