-- Chat needs live message delivery — add messages to the Realtime
-- publication so ChatScreen's postgres_changes subscription actually
-- receives inserts. Tables are not added to supabase_realtime
-- automatically on creation.
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
