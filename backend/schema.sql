--
-- PostgreSQL database dump
--

\restrict C3GZPn7VEfhgg82hmtpK9taR5fNAj4LBvkM2QINc94aMdstNtBDlsEke7SenzSK

-- Dumped from database version 17.4
-- Dumped by pg_dump version 18.3 (Ubuntu 18.3-1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: municipio; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.municipio (
    codigo_municipio_dv character(7) NOT NULL,
    codigo_municipio character(6),
    nome_municipio character varying(40) NOT NULL,
    cd_uf character(2) NOT NULL,
    municipio_capital character varying(5) NOT NULL,
    longitude numeric(15,7) NOT NULL,
    latitude numeric(15,7) NOT NULL
);


--
-- Name: regiao; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.regiao (
    cd_regiao character(2) NOT NULL,
    nome_regiao character varying(12) NOT NULL
);


--
-- Name: unidade_federacao; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.unidade_federacao (
    cd_uf character(2) NOT NULL,
    sigla_uf character(2) NOT NULL,
    nome_uf character varying(20) NOT NULL,
    cd_regiao character(2) NOT NULL
);


--
-- Name: sus_aih; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sus_aih (
    ano_aih character(4) NOT NULL,
    mes_aih character(2) NOT NULL,
    codigo_municipio_dv character(7) NOT NULL,
    codigo_municipio character(6),
    nome_municipio character(32),
    regiao_codigo integer,
    regiao_nome character varying(12),
    uf_codigo character(2),
    uf_sigla character(2),
    uf_nome character varying(20),
    municipio_capital character(3),
    numero_habitantes integer,
    faixa_populacao character varying(255),
    faixa_populacao_fpm character varying(255),
    qtd_0101 integer,
    qtd_01 integer,
    qtd_0201 integer,
    qtd_0202 integer,
    qtd_0203 integer,
    qtd_0204 integer,
    qtd_0205 integer,
    qtd_0206 integer,
    qtd_0207 integer,
    qtd_0208 integer,
    qtd_0209 integer,
    qtd_0210 integer,
    qtd_0211 integer,
    qtd_0212 integer,
    qtd_0214 integer,
    qtd_02 integer,
    qtd_0301 integer,
    qtd_0302 integer,
    qtd_0303 integer,
    qtd_0304 integer,
    qtd_0305 integer,
    qtd_0306 integer,
    qtd_0307 integer,
    qtd_0308 integer,
    qtd_0309 integer,
    qtd_0310 integer,
    qtd_03 integer,
    qtd_0401 integer,
    qtd_0402 integer,
    qtd_0403 integer,
    qtd_0404 integer,
    qtd_0405 integer,
    qtd_0406 integer,
    qtd_0407 integer,
    qtd_0408 integer,
    qtd_0409 integer,
    qtd_0410 integer,
    qtd_0411 integer,
    qtd_0412 integer,
    qtd_0413 integer,
    qtd_0414 integer,
    qtd_0415 integer,
    qtd_0416 integer,
    qtd_0418 integer,
    qtd_04 integer,
    qtd_0501 integer,
    qtd_0502 integer,
    qtd_0503 integer,
    qtd_0504 integer,
    qtd_0505 integer,
    qtd_0506 integer,
    qtd_05 integer,
    qtd_0603 integer,
    qtd_06 integer,
    qtd_0702 integer,
    qtd_07 integer,
    qtd_0801 integer,
    qtd_0802 integer,
    qtd_08 integer,
    qtd_total integer,
    vl_0201 numeric,
    vl_0202 numeric,
    vl_0203 numeric,
    vl_0204 numeric,
    vl_0205 numeric,
    vl_0206 numeric,
    vl_0207 numeric,
    vl_0208 numeric,
    vl_0209 numeric,
    vl_0210 numeric,
    vl_0211 numeric,
    vl_0212 numeric,
    vl_0214 numeric,
    vl_02 numeric,
    vl_0301 numeric,
    vl_0302 numeric,
    vl_0303 numeric,
    vl_0304 numeric,
    vl_0305 numeric,
    vl_0306 numeric,
    vl_0307 numeric,
    vl_0308 numeric,
    vl_0309 numeric,
    vl_0310 numeric,
    vl_03 numeric,
    vl_0401 numeric,
    vl_0402 numeric,
    vl_0403 numeric,
    vl_0404 numeric,
    vl_0405 numeric,
    vl_0406 numeric,
    vl_0407 numeric,
    vl_0408 numeric,
    vl_0409 numeric,
    vl_0410 numeric,
    vl_0411 numeric,
    vl_0412 numeric,
    vl_0413 numeric,
    vl_0414 numeric,
    vl_0415 numeric,
    vl_0416 numeric,
    vl_0417 numeric,
    vl_0418 numeric,
    vl_04 numeric,
    vl_0501 numeric,
    vl_0502 numeric,
    vl_0503 numeric,
    vl_0504 numeric,
    vl_0505 numeric,
    vl_0506 numeric,
    vl_05 numeric,
    vl_0603 numeric,
    vl_06 numeric,
    vl_0702 numeric,
    vl_07 numeric,
    vl_0801 numeric,
    vl_0802 numeric,
    vl_08 numeric,
    vl_total numeric,
    longitude numeric(15,7),
    latitude numeric(15,7)
);


--
-- Name: sus_aih pk_aih; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sus_aih
    ADD CONSTRAINT pk_aih PRIMARY KEY (codigo_municipio_dv, ano_aih, mes_aih);


--
-- Name: municipio pk_municipio; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.municipio
    ADD CONSTRAINT pk_municipio PRIMARY KEY (codigo_municipio_dv);


--
-- Name: regiao pk_regiao; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regiao
    ADD CONSTRAINT pk_regiao PRIMARY KEY (cd_regiao);


--
-- Name: unidade_federacao pk_unidade_federacao; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unidade_federacao
    ADD CONSTRAINT pk_unidade_federacao PRIMARY KEY (cd_uf);


--
-- Name: municipio uk_municipio; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.municipio
    ADD CONSTRAINT uk_municipio UNIQUE (codigo_municipio);


--
-- Name: sus_aih fk_aih_codigo_municipio; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sus_aih
    ADD CONSTRAINT fk_aih_codigo_municipio FOREIGN KEY (codigo_municipio_dv) REFERENCES public.municipio(codigo_municipio_dv);


--
-- Name: municipio fk_municipio_unidade_federacao; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.municipio
    ADD CONSTRAINT fk_municipio_unidade_federacao FOREIGN KEY (cd_uf) REFERENCES public.unidade_federacao(cd_uf);


--
-- Name: unidade_federacao fk_unidade_federacao_regiao; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unidade_federacao
    ADD CONSTRAINT fk_unidade_federacao_regiao FOREIGN KEY (cd_regiao) REFERENCES public.regiao(cd_regiao);


--
-- PostgreSQL database dump complete
--

\unrestrict C3GZPn7VEfhgg82hmtpK9taR5fNAj4LBvkM2QINc94aMdstNtBDlsEke7SenzSK

