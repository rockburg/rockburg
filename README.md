# Rockburg

[Rockburg](https://rockburg.com) is a music industry simulation game where you manage bands. Sign artists, record albums, book tours, and compete to build the most successful label in the industry. This simulation is driven by a deep set of game mechanics that model real music industry dynamics.

## Community

- Join our Discord server to connect with other players, share strategies, and get help: [Rockburg Discord](https://discord.gg/U66NKXJ4CH)
- Follow us on X at [@PlayRockburg](https://twitter.com/PlayRockburg)

## Game Overview

In Rockburg, players take on the role of a music manager who:
- Discovers and signs promising artists
- Helps artists develop their skills and careers
- Produces albums and singles
- Books shows and organizes tours
- Builds a record label and industry reputation
- Competes against other managers

The game features AI-generated artists with unique personalities, skills, and musical styles, making every playthrough different.

## Development Status

This project is being developed in phases:

- **Phase 0**: App Core (Completed)
  - User model with authentication
  - Pages controller for static content

- **Phase 1**: Artist Generation (In Progress)
  - AI-powered artist generation using OpenAI
  - Season management with automatic artist generation
  - Background job processing for artist creation

- **Future Phases** will include:
  - Music creation mechanics
  - Live performance & touring
  - Label management
  - Industry relationships
  - See the roadmap for complete details

## Technical Architecture

Rockburg is built with:

- **Ruby 3.3.4** and **Rails 8.0.1**
- **PostgreSQL** for the database
- **Redis** for caching and Sidekiq queues
- **Hotwire** (Turbo + Stimulus) for reactive UIs
- **TailwindCSS** for styling
- **Sidekiq** for background job processing
- **OpenAI API** for AI-powered content generation
- **Importmaps** for JavaScript dependencies

The application follows a domain-driven design approach with:
- Core game mechanics implemented as service objects
- Background processing for time-based and AI generation activities
- Real-time updates using Turbo Streams

## Getting Started

### Prerequisites

- **Ruby 3.3.4** (recommended to use [rbenv](https://github.com/rbenv/rbenv) or [asdf](https://asdf-vm.com/))
- **PostgreSQL 14+** installed and running
- **Redis 6+** installed and running
- **Node.js 18+** and **Yarn** for asset compilation
- **OpenAI API key** for artist generation

### Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/rockburg/rockburg.git
   cd rockburg
   ```

2. **Install dependencies**

   ```bash
   bundle install
   ```

3. **Configure environment variables**

   Create a `.env` file in the project root:

   ```
   OPENAI_API_KEY=your_api_key_here
   REDIS_URL=redis://localhost:6379/0
   ```

4. **Setup the database**

   ```bash
   rails db:create
   rails db:migrate
   rails db:seed  # Loads initial game data
   ```

5. **Start the development servers**

   ```bash
   bin/dev
   ```

6. **Access the application**

   Visit `http://localhost:3000` in your browser


## Development Workflow

### Game Reset and Data Generation

For development and testing, you can reset the game state and generate fresh data:

```bash
# Reset with default number of artists (50) and venues (25)
bundle exec rake dev:reset
```

This task:
- Deactivates all existing seasons
- Resets all managers to their initial state
- Clears scheduled actions and transactions
- Removes all existing artists
- Creates a new active season
- Generates new artists in the background
- Generates venues


### Development Best Practices

1. **Test-Driven Development**
   - Write tests before implementing features
   - Run the test suite frequently to ensure nothing breaks
   - Keep test coverage high

2. **Code Organization**
   - Follow the domain-driven design structure
   - Put game mechanics logic in service objects
   - Use background jobs for long-running processes

3. **UI Development**
   - Use Stimulus controllers for interactive elements
   - Build UI components using Turbo Frames for partial updates
   - Follow TailwindCSS conventions

4. **AI Integration**
   - Use OpenAI for content generation in background jobs
   - Cache responses to minimize API calls
   - Implement fallbacks for when the API is unavailable

### Logging and Debugging

- **Rails Logs**: Check `log/development.log` for application logs
- **Sidekiq Logs**: Check `log/sidekiq.log` for background job logs
- **AI Generation Logs**: Special logs for OpenAI calls in `log/openai.log`

## Testing

This project follows Test-Driven Development (TDD) principles using Minitest.

### Running Tests

```bash
# Run all tests
rails test

# Run system tests
rails test:system

# Run a specific test file
rails test test/models/artist_test.rb

# Run with verbose output
rails test -v
```

## Game Mechanics

The game is built on a complex set of mechanics defined in `game-mechanics.mdc`. These include:

- **Artist Attributes**: Talent, charisma, resilience, creativity, discipline
- **Skill Development**: Practice, recording, live performance growth over time
- **Music Creation**: Song and album creation with quality calculations
- **Performance System**: Venue tiers, show quality, audience reactions
- **Business Management**: Contracts, revenue streams, marketing effects

For more details, refer to the game mechanics documentation.

## Contributing

Contributions are welcome! Here's how to contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for your feature
4. Implement your feature
5. Make sure all tests pass
6. Commit your changes with descriptive commit messages
7. Push to your branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

### Pull Request Guidelines

- Ensure all tests are passing
- Update documentation if necessary
- Follow the established code style
- Include thorough description of changes

## Additional Resources

- [Game Mechanics Documentation](docs/game-mechanics.md)
- [Technical Implementation Guide](docs/technical.md)
- [Development Roadmap](docs/roadmap.md)

## License

Rockburg is distributed under an [AGPLv3 license](LICENSE).
