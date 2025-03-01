# Rockburg

Rockburg is a music industry simulation game where you can create and manage your own record label. Sign artists, record albums, book tours, and try to make it to the top of the charts.

## Development Status

This project is being developed in phases. Current status:

- **Phase 0**: App Core (Completed)
  - User model with authentication
  - Pages controller for static content
- **Phase 1**: Artist Generation (In Progress)
  - AI-powered artist generation using OpenAI
  - Season management with automatic artist generation
  - Background job processing for artist creation

## Technical Details

- Ruby 3.3.4
- Rails 8.0.1
- PostgreSQL database
- TailwindCSS for styling
- Sidekiq for background job processing
- OpenAI API for AI-powered content generation

## Getting Started

### Prerequisites

- Ruby 3.3.4 (recommended to use rbenv)
- PostgreSQL
- Node.js and Yarn
- Redis (for Sidekiq)
- OpenAI API key

### Setup

1. Clone the repository
2. Install dependencies:
   ```
   bundle install
   ```
3. Setup the database:
   ```
   rails db:setup
   ```
4. Configure environment variables:
   ```
   OPENAI_API_KEY=your_api_key
   REDIS_URL=redis://localhost:6379/0 (optional, defaults to this)
   ```
5. Start the server and Sidekiq:
   ```
   bin/dev                # Rails server with asset compilation
   bundle exec sidekiq    # In a separate terminal
   ```

## Artist Generation

The game uses OpenAI's API to generate realistic artist profiles. Artists are generated:

1. Automatically when a new season is activated (based on the configured artist count)
2. Manually through the admin interface for a season

The generation process runs in the background using Sidekiq to avoid blocking the UI.

## Testing

This project follows Test-Driven Development (TDD) principles. Run the tests with:

```
rails test
```

## License

This project is licensed under the MIT License.
