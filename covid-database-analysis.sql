/****** Questão 1 ******/
-- OBS: Colher tempo de execução e as 20 primeiras tuplas para cada consulta

-- 	Parte 1: consulta frequente disponibilizada 
SELECT * FROM exames ex
JOIN pacientes p ON p . id_paciente = ex . id_paciente
JOIN desfechos d ON p . id_paciente = d . id_paciente
WHERE ex . de_origem = 'Unidades de Internação'
LIMIT 20;

EXPLAIN ANALYZE
	SELECT * FROM exames ex
	JOIN pacientes p ON p.id_paciente = ex.id_paciente
	JOIN desfechos d ON p.id_paciente = d.id_paciente
	WHERE ex.de_origem = 'Unidades de Internação';
	
-- Parte 2: consulta frequente disponibilizada com uso de índices
CREATE INDEX origExUnidIntern ON exames(id_exame)
	WHERE de_origem = 'Unidades de Internação';

EXPLAIN ANALYZE
	SELECT * FROM exames ex
	JOIN pacientes p ON p.id_paciente = ex.id_paciente
	JOIN desfechos d ON p.id_paciente = d.id_paciente
	WHERE ex.de_origem = 'Unidades de Internação';

-- Parte 3: consulta frequente proposta
---- Contar quantos pacientes, agrupados por idade, testaram positivo para covid em um determinado mês 
SELECT (EXTRACT(YEAR FROM e.dt_coleta) - p.aa_nascimento) AS idade, COUNT(e.*) AS casos_positivos  
	FROM pacientes p, exames e
WHERE p.id_paciente = e.id_paciente
	AND upper(e.de_resultado) LIKE '%POSITIVO%'
	AND upper(e.de_exame) LIKE '%COVID%'
	AND upper(e.de_resultado) NOT LIKE '%A DINÂMICA DE PRODUÇÃO DE ANTICORPOS NA COVID-19 AINDA NÃO É BEM ESTABELECIDA%'
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
		AND upper(e.de_resultado) NOT LIKE '%A DINÂMICA DE PRODUÇÃO DE ANTICORPOS NA COVID-19 AINDA NÃO É BEM ESTABELECIDA%'
		AND to_char(e.dt_coleta, 'YYYY-MM') = '2020-12'
	GROUP BY idade
	ORDER BY casos_positivos DESC;

-- Parte 4: consulta frequente proposta com uso de índices
CREATE INDEX exameCovid ON exames(id_exame)
	WHERE upper(de_exame) LIKE '%COVID%';

EXPLAIN ANALYZE
	SELECT (EXTRACT(YEAR FROM e.dt_coleta) - p.aa_nascimento) AS idade, COUNT(e.*) AS casos_positivos   
		FROM pacientes p, exames e
	WHERE p.id_paciente = e.id_paciente
		AND upper(e.de_resultado) LIKE '%POSITIVO%'
		AND upper(e.de_exame) LIKE '%COVID%'
		AND upper(e.de_resultado) NOT LIKE '%A DINÂMICA DE PRODUÇÃO DE ANTICORPOS NA COVID-19 AINDA NÃO É BEM ESTABELECIDA%'
		AND to_char(e.dt_coleta, 'YYYY-MM') = '2020-12'
	GROUP BY idade
	ORDER BY casos_positivos DESC;

/* 
	RELATÓRIO: Justificar a consulta criada e a implementação do índice de acordo com a consulta, explicitando o
	porquê do índice otimizar tal consulta, conforme visto durante as aulas.
*/

/****** Questão 2 ******/

-- 	Parte 1: rotina para criar senha automática para novos pacientes que serão inseridos na base
CREATE EXTENSION pgcrypto;
CREATE OR REPLACE FUNCTION password_hash(passwordString TEXT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
	DECLARE MessageText TEXT;
		HintText TEXT;
	BEGIN
		IF passwordString IS NULL OR passwordString = '' THEN -- Conferindo se não é nulo
			RAISE EXCEPTION null_value_not_allowed USING MESSAGE = 'Senha nula', HINT = 'Insira uma senha para ober seu retorno criptografado';
			RETURN NULL;
		ELSE -- Retornando senha criptografada
			RETURN crypt(passwordString, gen_salt('md5'));
		END IF;
	EXCEPTION -- Imprimindo exceções encontradas
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS MessageText = MESSAGE_TEXT,	HintText = PG_EXCEPTION_HINT;
				RAISE NOTICE E'Erro: %\nMensagem: %\nDica: %',
				SQLSTATE, MessageText, HintText;
	END;
$$

-- Adicionando campo pwd na tabela pacientes
ALTER TABLE pacientes
    ADD COLUMN pwd text;
	
-- Criando tabela temporária
CREATE TABLE temp_pacientes AS 
	SELECT * FROM pacientes LIMIT 5;

-- Atualizando senhas usando função de hash
UPDATE temp_pacientes
	SET pwd = password_hash(CONCAT(id_paciente, ic_sexo, aa_nascimento));

-- Verificando atualização
SELECT * FROM pacientes LIMIT 5;
SELECT * FROM temp_pacientes;

-- Testando autenticação
SELECT (pwd = crypt(CONCAT(id_paciente, ic_sexo, aa_nascimento), pwd)) AS pswmatch FROM temp_pacientes WHERE id_paciente = '8F3A4E28494D5DC7CE33BCB1DD4A3B50';
-- Retorno esperado: true
SELECT (pwd = crypt(CONCAT('senha errada'), pwd)) AS pswmatch FROM temp_pacientes WHERE id_paciente = '8F3A4E28494D5DC7CE33BCB1DD4A3B50';
-- Retorno esperado: false

-- Removendo tabela temporária
DROP TABLE temp_pacientes;

-- Atualizando senhas usando função hash
UPDATE pacientes
	SET pwd = password_hash(CONCAT(id_paciente, ic_sexo, aa_nascimento));
	
-- Criando trigger para criar senhas automaticamente após o paciente ser inseiro
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

-- 	Parte 2: criar tabela LogAcesso (data/hora, tipo de operação e tabela requisitada/alterada)
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
		IF INSERTING THEN operacao := ‘I’;
		ELSIF UPDATING THEN operacao := ‘U’;
		ELSIF DELETING THEN operacao := ‘D’;
		END IF;
		INSERT INTO LogAcesso
		VALUES (USER, SYSDATE, operacao);
	END;

CREATE OR REPLACE TRIGGER LogExames
	AFTER INSERT OR UPDATE OR DELETE ON exames
	FOR EACH ROW
	DECLARE	operacao CHAR;
	BEGIN
		IF INSERTING THEN operacao := ‘I’;
		ELSIF UPDATING THEN operacao := ‘U’;
		ELSIF DELETING THEN operacao := ‘D’;
		END IF;
		INSERT INTO LogAcesso
		VALUES (USER, SYSDATE, operacao);
	END;

CREATE OR REPLACE TRIGGER LogDesfechos
	AFTER INSERT OR UPDATE OR DELETE ON desfechos
	FOR EACH ROW
	DECLARE	operacao CHAR;
	BEGIN
		IF INSERTING THEN operacao := ‘I’;
		ELSIF UPDATING THEN operacao := ‘U’;
		ELSIF DELETING THEN operacao := ‘D’;
		END IF;
		INSERT INTO LogAcesso
		VALUES (USER, SYSDATE, operacao);
	END;

/* 	Parte 3: rotina para criar logs na tabela LogAcesso quando os acessos e transações são realizados na base de dados
OBS: deve analisar três situações pertinentes para realizar a coleta da informação automaticamente */

/* 
	RELATÓRIO: as situações devem ser devidamente registradas e validadas por meios
	de testes, além de serem sucintamente explicadas, em relação a semântica da
	operação e relevância para o sistema em si.
*/

/****** Questão 3 ******/

/* 	Parte 1: Que tipo de informações relacionadas a COVID é possível recuperar analisando
os tipos de exames e analitos registrados? */

/* 	Parte 2: Analisando a quantidade de registros de um determinado exame de COVID em
relação a data de coleta ou período (por exemplo semanal), é possível indicar tendências de alta
e/ou baixa que auxiliariam a especialistas médicos em analises futuras? */

/* 	Parte 3: Que tipo de informações adicionais, em versões futuras da base de dados, poderiam
ser coletadas em novos hospitais para melhorar a qualidade dos dados analisados? */

/* 
	RELATÓRIO: é necessário realizar uma análise exploratória nos dados, selecionando informações relevantes
	com base em algum critério pertinente, justificando sua relevância no auxílio a especialistas.
*/