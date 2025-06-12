CREATE TABLE IF NOT EXISTS facts (
    id      bigint     NOT NULL PRIMARY KEY,
    state   char(1)    NOT NULL DEFAULT 'I',
    processed boolean  NOT NULL DEFAULT false
);

COMMENT ON TABLE facts IS 'simple facts';
