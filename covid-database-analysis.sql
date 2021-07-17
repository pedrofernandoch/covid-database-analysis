/****** Quest�o 1 ******/
-- OBS: Colher tempo de execu��o e as 20 primeiras tuplas para cada consulta

-- 	Parte 1: consulta frequente disponibilizada 
SELECT * FROM exames ex
JOIN pacientes p ON p . id_paciente = ex . id_paciente
JOIN desfechos d ON p . id_paciente = d . id_paciente
WHERE ex . de_origem = 'Unidades de Interna��o'
LIMIT 20;

EXPLAIN ANALYZE
	SELECT * FROM exames ex
	JOIN pacientes p ON p.id_paciente = ex.id_paciente
	JOIN desfechos d ON p.id_paciente = d.id_paciente
	WHERE ex.de_origem = 'Unidades de Interna��o';
	
-- Parte 2: consulta frequente disponibilizada com uso de �ndices
CREATE INDEX origExUnidIntern ON exames(id_exame)
	WHERE de_origem = 'Unidades de Interna��o';

EXPLAIN ANALYZE
	SELECT * FROM exames ex
	JOIN pacientes p ON p.id_paciente = ex.id_paciente
	JOIN desfechos d ON p.id_paciente = d.id_paciente
	WHERE ex.de_origem = 'Unidades de Interna��o';

-- Parte 3: consulta frequente proposta
---- Contar quantos pacientes, agrupados por idade, testaram positivo para covid em um determinado m�s 
SELECT (EXTRACT(YEAR FROM e.dt_coleta) - p.aa_nascimento) AS idade, COUNT(e.*) AS casos_positivos  
	FROM pacientes p, exames e
WHERE p.id_paciente = e.id_paciente
	AND upper(e.de_resultado) LIKE '%POSITIVO%'
	AND upper(e.de_exame) LIKE '%COVID%'
	AND upper(e.de_resultado) NOT LIKE '%A DIN�MICA DE PRODU��O DE ANTICORPOS NA COVID-19 AINDA N�O � BEM ESTABELECIDA%'
	AND to_char(e.dt_coleta, 'YYYY-MM') = '2020-12'
GROUP BY idade
ORDER BY casos_positivos DESC
LIMIT 20;

EXPLAIN ANALYZE
	SELECT (EXTRACT(YEAR FROM e.dt_coleta) - p.aa_nascimento) AS idade, COUNT(e.*) AS casos_positivos   
		FROM pacientes p, exames e
	WHERE p.id_paciente = e.id_paciente
		AND upper(e.de_resultado) LIKE '%POSITIVO%'
		AND upper(e.de_exame) LIKE '%COVID%'
		AND upper(e.de_resultado) NOT LIKE '%A DIN�MICA DE PRODU��O DE ANTICORPOS NA COVID-19 AINDA N�O � BEM ESTABELECIDA%'
		AND to_char(e.dt_coleta, 'YYYY-MM') = '2020-12'
	GROUP BY idade
	ORDER BY casos_positivos DESC;

-- Parte 4: consulta frequente proposta com uso de �ndices
CREATE INDEX exameCovid ON exames(id_exame)
	WHERE upper(de_exame) LIKE '%COVID%';

EXPLAIN ANALYZE
	SELECT (EXTRACT(YEAR FROM e.dt_coleta) - p.aa_nascimento) AS idade, COUNT(e.*) AS casos_positivos   
		FROM pacientes p, exames e
	WHERE p.id_paciente = e.id_paciente
		AND upper(e.de_resultado) LIKE '%POSITIVO%'
		AND upper(e.de_exame) LIKE '%COVID%'
		AND upper(e.de_resultado) NOT LIKE '%A DIN�MICA DE PRODU��O DE ANTICORPOS NA COVID-19 AINDA N�O � BEM ESTABELECIDA%'
		AND to_char(e.dt_coleta, 'YYYY-MM') = '2020-12'
	GROUP BY idade
	ORDER BY casos_positivos DESC;

/* 
	RELAT�RIO: Justificar a consulta criada e a implementa��o do �ndice de acordo com a consulta, explicitando o
	porqu� do �ndice otimizar tal consulta, conforme visto durante as aulas.
*/

/****** Quest�o 2 ******/

-- 	Parte 1: rotina para criar senha autom�tica para novos pacientes que ser�o inseridos na base
CREATE EXTENSION pgcrypto;
CREATE OR REPLACE FUNCTION password_hash(passwordString TEXT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
	DECLARE MessageText TEXT;
		HintText TEXT;
	BEGIN
		IF passwordString IS NULL OR passwordString = '' THEN -- Conferindo se n�o � nulo
			RAISE EXCEPTION null_value_not_allowed USING MESSAGE = 'Senha nula', HINT = 'Insira uma senha para ober seu retorno criptografado';
			RETURN NULL;
		ELSE -- Retornando senha criptografada
			RETURN crypt(passwordString, gen_salt('md5'));
		END IF;
	EXCEPTION -- Imprimindo exce��es encontradas
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS MessageText = MESSAGE_TEXT,	HintText = PG_EXCEPTION_HINT;
				RAISE NOTICE E'Erro: %\nMensagem: %\nDica: %',
				SQLSTATE, MessageText, HintText;
	END;
$$

-- Adicionando campo pwd na tabela pacientes
ALTER TABLE pacientes
    ADD COLUMN pwd text;
	
-- Criando tabela tempor�ria
CREATE TABLE temp_pacientes AS 
	SELECT * FROM pacientes LIMIT 5;

-- Atualizando senhas usando fun��o de hash
UPDATE temp_pacientes
	SET pwd = password_hash(CONCAT(id_paciente, ic_sexo, aa_nascimento));

-- Verificando atualiza��o
SELECT * FROM pacientes LIMIT 5;
SELECT * FROM temp_pacientes;

-- Testando autentica��o
SELECT (pwd = crypt(CONCAT(id_paciente, ic_sexo, aa_nascimento), pwd)) AS pswmatch FROM temp_pacientes WHERE id_paciente = '8F3A4E28494D5DC7CE33BCB1DD4A3B50';
-- Retorno esperado: true
SELECT (pwd = crypt(CONCAT('senha errada'), pwd)) AS pswmatch FROM temp_pacientes WHERE id_paciente = '8F3A4E28494D5DC7CE33BCB1DD4A3B50';
-- Retorno esperado: false

-- Removendo tabela tempor�ria
DROP TABLE temp_pacientes;

-- Atualizando senhas usando fun��o hash
UPDATE pacientes
	SET pwd = password_hash(CONCAT(id_paciente, ic_sexo, aa_nascimento));
	
-- Criando trigger para criar senhas automaticamente ap�s o paciente ser inseiro
CREATE TRIGGER setPwd
    AFTER INSERT ON pacientes
    FOR EACH ROW
	BEGIN
		NEW.pwd = password_hash(CONCAT(NEW.id_paciente, NEW.ic_sexo, NEW.aa_nascimento));
	END;
	
-- Testando trigger
INSERT INTO pacientes(
	id_paciente, ic_sexo, aa_nascimento, cd_pais, cd_uf, cd_municipio, cd_cepreduzido, id_hospital)
	VALUES ('?', '?', '?', '?', '?', '?', '?', '?');
	
SELECT * from pacientes WHERE id_paciente = '?';

-- 	Parte 2: criar tabela LogAcesso (data/hora, tipo de opera��o e tabela requisitada/alterada)
CREATE TABLE LogAcesso
(
    id bigserial NOT NULL,
	user 
    carimbo_de_tempo timestamp without time zone NOT NULL,
	operacao char NOT NULL,
    tabela char(30) NOT NULL,
    PRIMARY KEY (id)
);

CREATE OR REPLACE TRIGGER LogPacientes
	AFTER INSERT OR UPDATE OR DELETE ON pacientes
	FOR EACH ROW
	DECLARE	operacao CHAR;
	BEGIN
		IF INSERTING THEN operacao := �I�;
		ELSIF UPDATING THEN operacao := �U�;
		ELSIF DELETING THEN operacao := �D�;
		END IF;
		INSERT INTO LogAcesso
		VALUES (USER, SYSDATE, operacao);
	END;

CREATE OR REPLACE TRIGGER LogExames
	AFTER INSERT OR UPDATE OR DELETE ON exames
	FOR EACH ROW
	DECLARE	operacao CHAR;
	BEGIN
		IF INSERTING THEN operacao := �I�;
		ELSIF UPDATING THEN operacao := �U�;
		ELSIF DELETING THEN operacao := �D�;
		END IF;
		INSERT INTO LogAcesso
		VALUES (USER, SYSDATE, operacao);
	END;

CREATE OR REPLACE TRIGGER LogDesfechos
	AFTER INSERT OR UPDATE OR DELETE ON desfechos
	FOR EACH ROW
	DECLARE	operacao CHAR;
	BEGIN
		IF INSERTING THEN operacao := �I�;
		ELSIF UPDATING THEN operacao := �U�;
		ELSIF DELETING THEN operacao := �D�;
		END IF;
		INSERT INTO LogAcesso
		VALUES (USER, SYSDATE, operacao);
	END;

/* 	Parte 3: rotina para criar logs na tabela LogAcesso quando os acessos e transa��es s�o realizados na base de dados
OBS: deve analisar tr�s situa��es pertinentes para realizar a coleta da informa��o automaticamente */

/* 
	RELAT�RIO: as situa��es devem ser devidamente registradas e validadas por meios
	de testes, al�m de serem sucintamente explicadas, em rela��o a sem�ntica da
	opera��o e relev�ncia para o sistema em si.
*/

/****** Quest�o 3 ******/

/* 	Parte 1: Que tipo de informa��es relacionadas a COVID � poss�vel recuperar analisando
os tipos de exames e analitos registrados? */

/* 	Parte 2: Analisando a quantidade de registros de um determinado exame de COVID em
rela��o a data de coleta ou per�odo (por exemplo semanal), � poss�vel indicar tend�ncias de alta
e/ou baixa que auxiliariam a especialistas m�dicos em analises futuras? */

/* 	Parte 3: Que tipo de informa��es adicionais, em vers�es futuras da base de dados, poderiam
ser coletadas em novos hospitais para melhorar a qualidade dos dados analisados? */

/* 
	RELAT�RIO: � necess�rio realizar uma an�lise explorat�ria nos dados, selecionando informa��es relevantes
	com base em algum crit�rio pertinente, justificando sua relev�ncia no aux�lio a especialistas.
*/