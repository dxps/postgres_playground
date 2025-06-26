## PostgreSQL Listen & Notify

This is a sample setup of using PostgreSQL's Listen & Notify feature, which works similar with a Pub/Sub mechanism.

<br/>

### Setup

Have the following database objects created:

```sql
create table domain_events (
	id         bigserial    primary key,
	name       varchar(128) not null   ,
	content    text                    ,
	created_at timestamp    default now()
);

CREATE OR REPLACE FUNCTION notify_domain_events() RETURNS trigger AS $$
BEGIN
	PERFORM pg_notify('domain_events',
		json_build_object(
		 	'id', NEW.id,
			'name', NEW.name,
			'content', NEW.content,
			'created_at', NEW.created_at
		)::text
	);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER notify_chat_message_deleted AFTER insert ON domain_events
	FOR EACH ROW EXECUTE PROCEDURE notify_domain_events();
```

Any database client:

-   can then listen to the `domain_events` channel using `LISTEN domain_events` statement,
-   and thus get notified when a new domain event is added.

A new domain event can be added using:

```sql
insert into domain_events(name, content) values('fact1', 'some content 1');
```
