## Project Structure

- **Frontend**

  - React 18 with TypeScript
  - Tailwind CSS for styling
  - Components:

    - `Header.tsx`
    - `Sidebar.tsx`
    - `Dashboard.tsx`
- **Backend**

  - Go 1.22 with Chi router
  - PostgreSQL database

## API Endpoints

| Method | Path             | Description    |
|--------|------------------|----------------|
| GET    | `/api/users`     | List all users |
| POST   | `/api/users`     | Create a user  |
| GET    | `/api/users/:id` | Get user by ID |
| DELETE | `/api/users/:id` | Delete a user  |
