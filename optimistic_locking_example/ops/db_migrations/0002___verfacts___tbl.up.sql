CREATE TABLE IF NOT EXISTS verfacts (
    id      bigint     NOT NULL PRIMARY KEY,
    state   char(1)    NOT NULL DEFAULT 'I',
    processed boolean  NOT NULL DEFAULT false,
    version smallint   NOT NULL DEFAULT 1
);

COMMENT ON TABLE verfacts IS 'versioned facts';
