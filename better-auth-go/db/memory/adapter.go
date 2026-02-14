package memory

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/better-auth/better-auth-go/db"
	"github.com/better-auth/better-auth-go/types"
)

// Ensure MemoryAdapter implements db.Adapter
var _ db.Adapter = (*MemoryAdapter)(nil)

// MemoryAdapter is an in-memory database adapter for Better Auth.
type MemoryAdapter struct {
	users         map[string]*types.User
	sessions      map[string]*types.Session
	accounts      map[string]*types.Account
	verifications map[string]*types.Verification
	mu            sync.RWMutex
}

// NewMemoryAdapter creates a new MemoryAdapter.
func NewMemoryAdapter() *MemoryAdapter {
	return &MemoryAdapter{
		users:         make(map[string]*types.User),
		sessions:      make(map[string]*types.Session),
		accounts:      make(map[string]*types.Account),
		verifications: make(map[string]*types.Verification),
	}
}

// User methods

func (m *MemoryAdapter) CreateUser(ctx context.Context, user *types.User) (*types.User, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	user.CreatedAt = time.Now()
	user.UpdatedAt = time.Now()
	m.users[user.ID] = user
	return user, nil
}

func (m *MemoryAdapter) GetUser(ctx context.Context, id string) (*types.User, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	user, ok := m.users[id]
	if !ok {
		return nil, nil
	}
	return user, nil
}

func (m *MemoryAdapter) GetUserByEmail(ctx context.Context, email string) (*types.User, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	for _, user := range m.users {
		if user.Email == email {
			return user, nil
		}
	}
	return nil, nil
}

func (m *MemoryAdapter) UpdateUser(ctx context.Context, id string, user *types.User) (*types.User, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	existing, ok := m.users[id]
	if !ok {
		return nil, fmt.Errorf("user not found")
	}

	// Update fields
	existing.Email = user.Email
	existing.EmailVerified = user.EmailVerified
	existing.Name = user.Name
	existing.Image = user.Image
	existing.UpdatedAt = time.Now()

	m.users[id] = existing
	return existing, nil
}

func (m *MemoryAdapter) DeleteUser(ctx context.Context, id string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	delete(m.users, id)
	return nil
}

// Session methods

func (m *MemoryAdapter) CreateSession(ctx context.Context, session *types.Session) (*types.Session, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	session.CreatedAt = time.Now()
	session.UpdatedAt = time.Now()
	m.sessions[session.Token] = session
	return session, nil
}

func (m *MemoryAdapter) GetSession(ctx context.Context, token string) (*types.Session, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	session, ok := m.sessions[token]
	if !ok {
		return nil, nil
	}
	return session, nil
}

func (m *MemoryAdapter) UpdateSession(ctx context.Context, token string, session *types.Session) (*types.Session, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	existing, ok := m.sessions[token]
	if !ok {
		return nil, fmt.Errorf("session not found")
	}

	existing.ExpiresAt = session.ExpiresAt
	existing.UpdatedAt = time.Now()
	m.sessions[token] = existing
	return existing, nil
}

func (m *MemoryAdapter) DeleteSession(ctx context.Context, token string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	delete(m.sessions, token)
	return nil
}

func (m *MemoryAdapter) DeleteSessions(ctx context.Context, userId string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	for token, session := range m.sessions {
		if session.UserID == userId {
			delete(m.sessions, token)
		}
	}
	return nil
}

// Account methods

func (m *MemoryAdapter) CreateAccount(ctx context.Context, account *types.Account) (*types.Account, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	account.CreatedAt = time.Now()
	account.UpdatedAt = time.Now()
	key := fmt.Sprintf("%s:%s", account.ProviderID, account.AccountID)
	m.accounts[key] = account
	return account, nil
}

func (m *MemoryAdapter) GetAccount(ctx context.Context, providerId string, accountId string) (*types.Account, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	key := fmt.Sprintf("%s:%s", providerId, accountId)
	account, ok := m.accounts[key]
	if !ok {
		return nil, nil
	}
	return account, nil
}

func (m *MemoryAdapter) GetAccounts(ctx context.Context, userId string) ([]*types.Account, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	var accounts []*types.Account
	for _, account := range m.accounts {
		if account.UserID == userId {
			accounts = append(accounts, account)
		}
	}
	return accounts, nil
}

func (m *MemoryAdapter) UpdateAccount(ctx context.Context, providerId string, accountId string, account *types.Account) (*types.Account, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	key := fmt.Sprintf("%s:%s", providerId, accountId)
	existing, ok := m.accounts[key]
	if !ok {
		return nil, fmt.Errorf("account not found")
	}

	// Update fields
	existing.AccessToken = account.AccessToken
	existing.RefreshToken = account.RefreshToken
	existing.AccessTokenExpiresAt = account.AccessTokenExpiresAt
	existing.RefreshTokenExpiresAt = account.RefreshTokenExpiresAt
	existing.IDToken = account.IDToken
	existing.Scope = account.Scope
	existing.Password = account.Password
	existing.UpdatedAt = time.Now()

	m.accounts[key] = existing
	return existing, nil
}

func (m *MemoryAdapter) DeleteAccount(ctx context.Context, providerId string, accountId string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	key := fmt.Sprintf("%s:%s", providerId, accountId)
	delete(m.accounts, key)
	return nil
}

// Verification methods

func (m *MemoryAdapter) CreateVerification(ctx context.Context, verification *types.Verification) (*types.Verification, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	verification.CreatedAt = time.Now()
	verification.UpdatedAt = time.Now()
	key := fmt.Sprintf("%s:%s", verification.Identifier, verification.Value)
	m.verifications[key] = verification
	return verification, nil
}

func (m *MemoryAdapter) GetVerification(ctx context.Context, identifier string, value string) (*types.Verification, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	key := fmt.Sprintf("%s:%s", identifier, value)
	verification, ok := m.verifications[key]
	if !ok {
		return nil, nil
	}
	return verification, nil
}

func (m *MemoryAdapter) DeleteVerification(ctx context.Context, identifier string, value string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	key := fmt.Sprintf("%s:%s", identifier, value)
	delete(m.verifications, key)
	return nil
}
