package repos

import (
	"fmt"
	"time"

	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
)

const (
	insertSQL = `INSERT INTO verfacts (id) VALUES ($1)
				 ON CONFLICT (id) DO NOTHING;`
	updateProcessedSQL = `UPDATE verfacts SET processed = true, version = 2
	                      WHERE id = $1 AND version = 1 RETURNING id;`
)

// Versioned facts repo.
type VerFactsRepo struct {
	db *sqlx.DB
}

func NewVerFactsRepo(
	driver string,
	dataSourceName string,
	maxOpenConns int,
	maxIdleConns int,
	maxIdleTime string) (*VerFactsRepo, error) {

	connMaxIdleTime, err := time.ParseDuration(maxIdleTime)
	if err != nil {
		return nil, err
	}
	db, err := sqlx.Connect("postgres", dataSourceName)
	if err != nil {
		return nil, fmt.Errorf("error opening postgres db: %w", err)
	}
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("error connecting to postgres db: %w", err)
	}
	db.DB.SetMaxOpenConns(maxOpenConns)
	db.DB.SetMaxIdleConns(maxIdleConns)
	db.DB.SetConnMaxIdleTime(connMaxIdleTime)

	return &VerFactsRepo{db}, nil
}

func (r *VerFactsRepo) Add(id int) error {
	_, err := r.db.Exec(insertSQL, id)
	return err
}

func (r *VerFactsRepo) SetAsProcessed(id int) error {
	rs, err := r.db.Exec(updateProcessedSQL, id)
	if err != nil {
		return err
	}
	rows, err := rs.RowsAffected()
	if err != nil {
		return fmt.Errorf("error getting rows affected: %w", err)
	}
	if rows == 0 {
		return fmt.Errorf("no rows updated")
	}
	return nil
}
