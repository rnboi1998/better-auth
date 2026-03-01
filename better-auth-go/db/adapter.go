package db

import (
	"context"
	"github.com/better-auth/better-auth-go/types"
)

// Adapter interface defines the methods that a database adapter must implement.
type Adapter interface {
	// User
	CreateUser(ctx context.Context, user *types.User) (*types.User, error)
	GetUser(ctx context.Context, id string) (*types.User, error)
	GetUserByEmail(ctx context.Context, email string) (*types.User, error)
	UpdateUser(ctx context.Context, id string, user *types.User) (*types.User, error)
	DeleteUser(ctx context.Context, id string) error

	// Session
	CreateSession(ctx context.Context, session *types.Session) (*types.Session, error)
	GetSession(ctx context.Context, token string) (*types.Session, error)
	UpdateSession(ctx context.Context, token string, session *types.Session) (*types.Session, error)
	DeleteSession(ctx context.Context, token string) error
	DeleteSessions(ctx context.Context, userId string) error

	// Account
	CreateAccount(ctx context.Context, account *types.Account) (*types.Account, error)
	GetAccount(ctx context.Context, providerId string, accountId string) (*types.Account, error)
	GetAccounts(ctx context.Context, userId string) ([]*types.Account, error)
	UpdateAccount(ctx context.Context, providerId string, accountId string, account *types.Account) (*types.Account, error)
	DeleteAccount(ctx context.Context, providerId string, accountId string) error

	// Verification
	CreateVerification(ctx context.Context, verification *types.Verification) (*types.Verification, error)
	GetVerification(ctx context.Context, identifier string, value string) (*types.Verification, error)
	DeleteVerification(ctx context.Context, identifier string, value string) error
}
