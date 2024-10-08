PGDMP                         |            sign.pro    11.12    11.12 2    H           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                       false            I           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                       false            J           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                       false            K           1262 	   410243539    sign.pro    DATABASE     �   CREATE DATABASE "sign.pro" WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'English_United States.1252' LC_CTYPE = 'English_United States.1252';
    DROP DATABASE "sign.pro";
             postgres    false                        2615 	   410243540    SID    SCHEMA        CREATE SCHEMA "SID";
    DROP SCHEMA "SID";
             postgres    false            �            1255 	   410243541 !   clone_schema(text, text, boolean)    FUNCTION     �  CREATE FUNCTION public.clone_schema(source_schema text, dest_schema text, include_recs boolean) RETURNS void
    LANGUAGE plpgsql
    AS $$

--  This function will clone all sequences, tables, data, views & functions from any existing schema to a new one
-- SAMPLE CALL:
-- SELECT clone_schema('public', 'new_schema', TRUE);

DECLARE
  src_oid          oid;
  tbl_oid          oid;
  func_oid         oid;
  object           text;
  buffer           text;
  srctbl           text;
  default_         text;
  column_          text;
  qry              text;
  dest_qry         text;
  v_def            text;
  seqval           bigint;
  sq_last_value    bigint;
  sq_max_value     bigint;
  sq_start_value   bigint;
  sq_increment_by  bigint;
  sq_min_value     bigint;
  sq_cache_value   bigint;
  sq_log_cnt       bigint;
  sq_is_called     boolean;
  sq_is_cycled     boolean;
  sq_cycled        char(10);

BEGIN

-- Check that source_schema exists
  SELECT oid INTO src_oid
    FROM pg_namespace
   WHERE nspname = quote_ident(source_schema);
  IF NOT FOUND
    THEN 
    RAISE NOTICE 'source schema % does not exist!', source_schema;
    RETURN ;
  END IF;

  -- Check that dest_schema does not yet exist
  PERFORM nspname 
    FROM pg_namespace
   WHERE nspname = dest_schema;
  IF FOUND
    THEN 
    RAISE NOTICE 'dest schema % already exists!', dest_schema;
    RETURN ;
  END IF;

  EXECUTE 'CREATE SCHEMA ' || dest_schema;

  -- Create sequences
  -- TODO: Find a way to make this sequence's owner is the correct table.
  FOR object IN
    SELECT sequence_name::text 
      FROM information_schema.sequences
     WHERE sequence_schema = source_schema
  LOOP
    EXECUTE 'CREATE SEQUENCE ' || dest_schema || '.' || object;
    srctbl := source_schema || '.' || object;

    EXECUTE 'SELECT last_value, max_value, start_value, increment_by, min_value, cache_value, log_cnt, is_cycled, is_called 
              FROM ' || source_schema || '.' || object || ';' 
              INTO sq_last_value, sq_max_value, sq_start_value, sq_increment_by, sq_min_value, sq_cache_value, sq_log_cnt, sq_is_cycled, sq_is_called ; 

    IF sq_is_cycled 
      THEN 
        sq_cycled := 'CYCLE';
    ELSE
        sq_cycled := 'NO CYCLE';
    END IF;
	
    EXECUTE 'ALTER SEQUENCE '   || dest_schema || '.' || object
            || ' INCREMENT BY ' || sq_increment_by
            || ' MINVALUE '     || sq_min_value 
            || ' MAXVALUE '     || sq_max_value
            || ' START WITH '   || sq_start_value
            || ' RESTART '      || sq_min_value 
            || ' CACHE '        || sq_cache_value 
            || sq_cycled || ' ;' ;

    buffer := dest_schema || '.' || object;
    IF include_recs 
        THEN
            EXECUTE 'SELECT setval( ''' || buffer || ''', ' || sq_last_value || ', ' || sq_is_called || ');' ; 
    ELSE
            EXECUTE 'SELECT setval( ''' || buffer || ''', ' || sq_start_value || ', ' || sq_is_called || ');' ;
    END IF;

  END LOOP;

-- Create tables 
  FOR object IN
    SELECT TABLE_NAME::text 
      FROM information_schema.tables 
     WHERE table_schema = source_schema
       AND table_type = 'BASE TABLE'

  LOOP
    buffer := dest_schema || '.' || object;
    EXECUTE 'CREATE TABLE ' || buffer || ' (LIKE ' || source_schema || '.' || object
        || ' INCLUDING ALL)';

    IF include_recs 
      THEN 
      -- Insert records from source table
      EXECUTE 'INSERT INTO ' || buffer || ' SELECT * FROM ' || source_schema || '.' || object || ';';
    END IF;
 
    FOR column_, default_ IN
      SELECT column_name::text, 
             REPLACE(column_default::text, source_schema, dest_schema) 
        FROM information_schema.COLUMNS 
       WHERE table_schema = dest_schema 
         AND TABLE_NAME = object 
         AND column_default LIKE 'nextval(%' || source_schema || '%::regclass)'
    LOOP
      EXECUTE 'ALTER TABLE ' || buffer || ' ALTER COLUMN ' || column_ || ' SET DEFAULT ' || default_;
    END LOOP;

  END LOOP;

--  add FK constraint
  FOR qry IN
    SELECT 'ALTER TABLE ' || dest_schema || '.' || rn.relname
                          || ' ADD CONSTRAINT ' || ct.conname || ' ' || pg_get_constraintdef(ct.oid) || ';'
      FROM pg_constraint ct
      JOIN pg_class rn ON rn.oid = ct.conrelid
     WHERE connamespace = src_oid
       AND rn.relkind = 'r'
       AND ct.contype = 'f'
         
    LOOP
      EXECUTE qry;

    END LOOP;


-- Create views 
  FOR object IN
    SELECT table_name::text,
           view_definition 
      FROM information_schema.views
     WHERE table_schema = source_schema

  LOOP
    buffer := dest_schema || '.' || object;
    SELECT view_definition INTO v_def
      FROM information_schema.views
     WHERE table_schema = source_schema
       AND table_name = object;
     
    EXECUTE 'CREATE OR REPLACE VIEW ' || buffer || ' AS ' || v_def || ';' ;

  END LOOP;

-- Create functions 
  FOR func_oid IN
    SELECT oid
      FROM pg_proc 
     WHERE pronamespace = src_oid

  LOOP      
    SELECT pg_get_functiondef(func_oid) INTO qry;
    SELECT replace(qry, source_schema, dest_schema) INTO dest_qry;
    EXECUTE dest_qry;

  END LOOP;
  
  RETURN; 
 
END;
 
$$;
 _   DROP FUNCTION public.clone_schema(source_schema text, dest_schema text, include_recs boolean);
       public       postgres    false            �            1255 	   410243543    uuid_generate_v1()    FUNCTION     }   CREATE FUNCTION public.uuid_generate_v1() RETURNS uuid
    LANGUAGE c STRICT
    AS '$libdir/uuid-ossp', 'uuid_generate_v1';
 )   DROP FUNCTION public.uuid_generate_v1();
       public       postgres    false            �            1255 	   410243544    uuid_generate_v1mc()    FUNCTION     �   CREATE FUNCTION public.uuid_generate_v1mc() RETURNS uuid
    LANGUAGE c STRICT
    AS '$libdir/uuid-ossp', 'uuid_generate_v1mc';
 +   DROP FUNCTION public.uuid_generate_v1mc();
       public       postgres    false            �            1255 	   410243545    uuid_generate_v3(uuid, text)    FUNCTION     �   CREATE FUNCTION public.uuid_generate_v3(namespace uuid, name text) RETURNS uuid
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/uuid-ossp', 'uuid_generate_v3';
 B   DROP FUNCTION public.uuid_generate_v3(namespace uuid, name text);
       public       postgres    false            �            1255 	   410243546    uuid_generate_v4()    FUNCTION     }   CREATE FUNCTION public.uuid_generate_v4() RETURNS uuid
    LANGUAGE c STRICT
    AS '$libdir/uuid-ossp', 'uuid_generate_v4';
 )   DROP FUNCTION public.uuid_generate_v4();
       public       postgres    false            �            1255 	   410243547    uuid_generate_v5(uuid, text)    FUNCTION     �   CREATE FUNCTION public.uuid_generate_v5(namespace uuid, name text) RETURNS uuid
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/uuid-ossp', 'uuid_generate_v5';
 B   DROP FUNCTION public.uuid_generate_v5(namespace uuid, name text);
       public       postgres    false            �            1255 	   410243548 
   uuid_nil()    FUNCTION     w   CREATE FUNCTION public.uuid_nil() RETURNS uuid
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/uuid-ossp', 'uuid_nil';
 !   DROP FUNCTION public.uuid_nil();
       public       postgres    false            �            1255 	   410243549    uuid_ns_dns()    FUNCTION     }   CREATE FUNCTION public.uuid_ns_dns() RETURNS uuid
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/uuid-ossp', 'uuid_ns_dns';
 $   DROP FUNCTION public.uuid_ns_dns();
       public       postgres    false            �            1255 	   410243550    uuid_ns_oid()    FUNCTION     }   CREATE FUNCTION public.uuid_ns_oid() RETURNS uuid
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/uuid-ossp', 'uuid_ns_oid';
 $   DROP FUNCTION public.uuid_ns_oid();
       public       postgres    false            �            1255 	   410243551    uuid_ns_url()    FUNCTION     }   CREATE FUNCTION public.uuid_ns_url() RETURNS uuid
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/uuid-ossp', 'uuid_ns_url';
 $   DROP FUNCTION public.uuid_ns_url();
       public       postgres    false            �            1255 	   410243552    uuid_ns_x500()    FUNCTION        CREATE FUNCTION public.uuid_ns_x500() RETURNS uuid
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/uuid-ossp', 'uuid_ns_x500';
 %   DROP FUNCTION public.uuid_ns_x500();
       public       postgres    false            �            1259 	   410243553    partner_audit    TABLE     m  CREATE TABLE "SID".partner_audit (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    created_date timestamp(6) without time zone,
    created_by character varying(36),
    updated_date timestamp(6) without time zone,
    updated_by character varying(36),
    request jsonb NOT NULL,
    response jsonb NOT NULL,
    url character varying(512) NOT NULL
);
     DROP TABLE "SID".partner_audit;
       SID         postgres    false    212    6            �            1259 	   410243560    signature_log    TABLE       CREATE TABLE "SID".signature_log (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    created_date timestamp(6) without time zone,
    created_by character varying(36),
    updated_date timestamp without time zone,
    updated_by character varying(36),
    request jsonb NOT NULL,
    response jsonb,
    version bigint,
    merchant_id character varying(36),
    user_name character varying(512),
    password character varying(512),
    trans_id character varying(36),
    status integer,
    type integer
);
     DROP TABLE "SID".signature_log;
       SID         postgres    false    212    6            �            1259 	   410243567    __EFMigrationsHistory    TABLE     �   CREATE TABLE public."__EFMigrationsHistory" (
    "MigrationId" character varying(150) NOT NULL,
    "ProductVersion" character varying(32) NOT NULL
);
 +   DROP TABLE public."__EFMigrationsHistory";
       public         postgres    false            �            1259 	   410243570 	   audit_log    TABLE     �   CREATE TABLE public.audit_log (
    id bigint NOT NULL,
    inserted_date timestamp(6) without time zone DEFAULT now() NOT NULL,
    updated_date timestamp(6) without time zone DEFAULT now() NOT NULL,
    data jsonb NOT NULL
);
    DROP TABLE public.audit_log;
       public         postgres    false            �            1259 	   410243578    audit_log_id_seq    SEQUENCE     y   CREATE SEQUENCE public.audit_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.audit_log_id_seq;
       public       postgres    false    200            L           0    0    audit_log_id_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE public.audit_log_id_seq OWNED BY public.audit_log.id;
            public       postgres    false    201            �            1259 	   410243580    config    TABLE     d  CREATE TABLE public.config (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    created_date timestamp(6) without time zone,
    created_by character varying(36),
    updated_date timestamp(6) without time zone,
    updated_by character varying(36),
    value jsonb NOT NULL,
    key character varying(255) NOT NULL,
    application_id integer
);
    DROP TABLE public.config;
       public         postgres    false    212            �            1259 	   410243587 
   log_id_seq    SEQUENCE     s   CREATE SEQUENCE public.log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 !   DROP SEQUENCE public.log_id_seq;
       public       postgres    false            �            1259 	   410243589    signature_log_id_seq    SEQUENCE     }   CREATE SEQUENCE public.signature_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.signature_log_id_seq;
       public       postgres    false            �            1259 	   410243591 
   table_name    TABLE     �   CREATE TABLE public.table_name (
    exception text,
    level character varying(50),
    machine_name text,
    message text,
    message_template text,
    properties jsonb,
    props_test json,
    raise_date timestamp without time zone
);
    DROP TABLE public.table_name;
       public         postgres    false            �            1259 	   410243597    work_item_status    TABLE     �   CREATE TABLE public.work_item_status (
    id integer NOT NULL,
    work_item_id character varying(255) NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    status character varying(50) NOT NULL,
    message text
);
 $   DROP TABLE public.work_item_status;
       public         postgres    false            �            1259 	   410243603    workitemstatus_id_seq    SEQUENCE     �   CREATE SEQUENCE public.workitemstatus_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.workitemstatus_id_seq;
       public       postgres    false    206            M           0    0    workitemstatus_id_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.workitemstatus_id_seq OWNED BY public.work_item_status.id;
            public       postgres    false    207            �
           2604 	   410243605    audit_log id    DEFAULT     l   ALTER TABLE ONLY public.audit_log ALTER COLUMN id SET DEFAULT nextval('public.audit_log_id_seq'::regclass);
 ;   ALTER TABLE public.audit_log ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    201    200            �
           2604 	   410243606    work_item_status id    DEFAULT     x   ALTER TABLE ONLY public.work_item_status ALTER COLUMN id SET DEFAULT nextval('public.workitemstatus_id_seq'::regclass);
 B   ALTER TABLE public.work_item_status ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    207    206            ;          0 	   410243553    partner_audit 
   TABLE DATA               v   COPY "SID".partner_audit (id, created_date, created_by, updated_date, updated_by, request, response, url) FROM stdin;
    SID       postgres    false    197   �P       <          0 	   410243560    signature_log 
   TABLE DATA               �   COPY "SID".signature_log (id, created_date, created_by, updated_date, updated_by, request, response, version, merchant_id, user_name, password, trans_id, status, type) FROM stdin;
    SID       postgres    false    198   �P       =          0 	   410243567    __EFMigrationsHistory 
   TABLE DATA               R   COPY public."__EFMigrationsHistory" ("MigrationId", "ProductVersion") FROM stdin;
    public       postgres    false    199   �P       >          0 	   410243570 	   audit_log 
   TABLE DATA               J   COPY public.audit_log (id, inserted_date, updated_date, data) FROM stdin;
    public       postgres    false    200   �P       @          0 	   410243580    config 
   TABLE DATA               t   COPY public.config (id, created_date, created_by, updated_date, updated_by, value, key, application_id) FROM stdin;
    public       postgres    false    202   �P       C          0 	   410243591 
   table_name 
   TABLE DATA               �   COPY public.table_name (exception, level, machine_name, message, message_template, properties, props_test, raise_date) FROM stdin;
    public       postgres    false    205   Q       D          0 	   410243597    work_item_status 
   TABLE DATA               Z   COPY public.work_item_status (id, work_item_id, "timestamp", status, message) FROM stdin;
    public       postgres    false    206   1Q       N           0    0    audit_log_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.audit_log_id_seq', 172034936, true);
            public       postgres    false    201            O           0    0 
   log_id_seq    SEQUENCE SET     9   SELECT pg_catalog.setval('public.log_id_seq', 1, false);
            public       postgres    false    203            P           0    0    signature_log_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.signature_log_id_seq', 1, false);
            public       postgres    false    204            Q           0    0    workitemstatus_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.workitemstatus_id_seq', 3542, true);
            public       postgres    false    207            �
           2606 	   410269726     partner_audit partner_audit_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY "SID".partner_audit
    ADD CONSTRAINT partner_audit_pkey PRIMARY KEY (id);
 I   ALTER TABLE ONLY "SID".partner_audit DROP CONSTRAINT partner_audit_pkey;
       SID         postgres    false    197            �
           2606 	   410269728    signature_log signature_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY "SID".signature_log
    ADD CONSTRAINT signature_pkey PRIMARY KEY (id);
 E   ALTER TABLE ONLY "SID".signature_log DROP CONSTRAINT signature_pkey;
       SID         postgres    false    198            �
           2606 	   410269730 .   __EFMigrationsHistory PK___EFMigrationsHistory 
   CONSTRAINT     {   ALTER TABLE ONLY public."__EFMigrationsHistory"
    ADD CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY ("MigrationId");
 \   ALTER TABLE ONLY public."__EFMigrationsHistory" DROP CONSTRAINT "PK___EFMigrationsHistory";
       public         postgres    false    199            �
           2606 	   410269732    config config_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY public.config
    ADD CONSTRAINT config_pkey PRIMARY KEY (id);
 <   ALTER TABLE ONLY public.config DROP CONSTRAINT config_pkey;
       public         postgres    false    202            �
           2606 	   410269734    audit_log event_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT event_pkey PRIMARY KEY (id);
 >   ALTER TABLE ONLY public.audit_log DROP CONSTRAINT event_pkey;
       public         postgres    false    200            �
           2606 	   410269736 $   work_item_status workitemstatus_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.work_item_status
    ADD CONSTRAINT workitemstatus_pkey PRIMARY KEY (id);
 N   ALTER TABLE ONLY public.work_item_status DROP CONSTRAINT workitemstatus_pkey;
       public         postgres    false    206            �
           1259 	   410269737    audit_log_inserted_date_idx    INDEX     _   CREATE INDEX audit_log_inserted_date_idx ON public.audit_log USING btree (inserted_date DESC);
 /   DROP INDEX public.audit_log_inserted_date_idx;
       public         postgres    false    200            �
           1259 	   410269738    idx_workitemstatus_workitemid    INDEX     b   CREATE INDEX idx_workitemstatus_workitemid ON public.work_item_status USING btree (work_item_id);
 1   DROP INDEX public.idx_workitemstatus_workitemid;
       public         postgres    false    206            ;      x������ � �      <      x������ � �      =      x������ � �      >      x������ � �      @      x������ � �      C      x������ � �      D      x������ � �     