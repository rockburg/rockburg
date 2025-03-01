# Rockburg

Rockburg is a music industry simulation game where you can create and manage your own record label. Sign artists, record albums, book tours, and try to make it to the top of the charts.

## Development Status

This project is being developed in phases. Current status:

- **Phase 0**: App Core (Completed)
  - User model with authentication
  - Pages controller for static content

## Technical Details

- Ruby 3.3.4
- Rails 8.0.1
- PostgreSQL database
- TailwindCSS for styling

## Getting Started

### Prerequisites

- Ruby 3.3.4 (recommended to use rbenv)
- PostgreSQL
- Node.js and Yarn

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
4. Start the server:
   ```
   bin/dev
   ```

## Testing

This project follows Test-Driven Development (TDD) principles. Run the tests with:

```
rails test
```

## License

This project is licensed under the MIT License.
