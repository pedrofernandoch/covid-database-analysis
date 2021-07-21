/****** Questão 1 ******/
-- OBS: Colher tempo de execução e as 20 primeiras tuplas para cada consulta

-- 	Parte 1: consulta frequente disponibilizada 
SELECT * FROM exames ex
JOIN pacientes p ON p . id_paciente = ex . id_paciente
JOIN desfechos d ON p . id_paciente = d . id_paciente
WHERE ex.de_origem = 'Unidades de Internação'
LIMIT 20;

EXPLAIN ANALYZE
	SELECT * FROM exames ex
	JOIN pacientes p ON p.id_paciente = ex.id_paciente
	JOIN desfechos d ON p.id_paciente = d.id_paciente
	WHERE ex.de_origem = 'Unidades de Internação';
	
-- Parte 2: consulta frequente disponibilizada com uso de índices
CREATE INDEX origExUnidIntern ON exames(id_exame)
	WHERE de_origem = 'Unidades de Internação';
-- DROP INDEX origExUnidIntern;

EXPLAIN ANALYZE
	SELECT * FROM exames ex
	JOIN pacientes p ON p.id_paciente = ex.id_paciente
	JOIN desfechos d ON p.id_paciente = d.id_paciente
	WHERE ex.de_origem = 'Unidades de Internação';

-- Parte 3: consulta frequente proposta
---- Contar quantos pacientes, agrupados por idade, testaram positivo para covid em um determinado mês 
SELECT (EXTRACT(YEAR FROM e.dt_coleta) - p.aa_nascimento) AS idade, COUNT(DISTINCT e.id_paciente) AS casos_positivos  
	FROM pacientes p, exames e
WHERE p.id_paciente = e.id_paciente
	AND upper(e.de_exame) LIKE '%COVID%'
	AND (upper(e.de_resultado) LIKE '%POSITIVO%' 
			OR upper(e.de_resultado) LIKE 'DETECTADO%'
			OR upper(e.de_resultado) LIKE 'DETECTADOS ANTICORPOS%' 
			OR upper(e.de_resultado) LIKE 'REAGENTE%'
			OR upper(e.de_resultado) LIKE 'AMOSTRA REAGENTE%')
	AND upper(e.de_resultado) NOT LIKE '%A DINÂMICA DE PRODUÇÃO DE ANTICORPOS NA COVID-19 AINDA NÃO É BEM ESTABELECIDA%'
	AND to_char(e.dt_coleta, 'YYYY-MM') = '2020-12'
GROUP BY idade
ORDER BY casos_positivos DESC
LIMIT 20;

EXPLAIN ANALYZE
	SELECT (EXTRACT(YEAR FROM e.dt_coleta) - p.aa_nascimento) AS idade, COUNT(DISTINCT e.id_paciente) AS casos_positivos  
		FROM pacientes p, exames e
	WHERE p.id_paciente = e.id_paciente
		AND upper(e.de_exame) LIKE '%COVID%'
		AND (upper(e.de_resultado) LIKE '%POSITIVO%' 
				OR upper(e.de_resultado) LIKE 'DETECTADO%'
				OR upper(e.de_resultado) LIKE 'DETECTADOS ANTICORPOS%' 
				OR upper(e.de_resultado) LIKE 'REAGENTE%'
				OR upper(e.de_resultado) LIKE 'AMOSTRA REAGENTE%')
		AND upper(e.de_resultado) NOT LIKE '%A DINÂMICA DE PRODUÇÃO DE ANTICORPOS NA COVID-19 AINDA NÃO É BEM ESTABELECIDA%'
		AND to_char(e.dt_coleta, 'YYYY-MM') = '2020-12'
	GROUP BY idade
	ORDER BY casos_positivos DESC;

-- Parte 4: consulta frequente proposta com uso de índices
CREATE INDEX exameCovid ON exames(id_exame)
	WHERE upper(de_exame) LIKE '%COVID%';
-- DROP INDEX exameCovid;

EXPLAIN ANALYZE
	SELECT (EXTRACT(YEAR FROM e.dt_coleta) - p.aa_nascimento) AS idade, COUNT(DISTINCT e.id_paciente) AS casos_positivos  
		FROM pacientes p, exames e
	WHERE p.id_paciente = e.id_paciente
		AND upper(e.de_exame) LIKE '%COVID%'
		AND (upper(e.de_resultado) LIKE '%POSITIVO%' 
				OR upper(e.de_resultado) LIKE 'DETECTADO%'
				OR upper(e.de_resultado) LIKE 'DETECTADOS ANTICORPOS%' 
				OR upper(e.de_resultado) LIKE 'REAGENTE%'
				OR upper(e.de_resultado) LIKE 'AMOSTRA REAGENTE%')
		AND upper(e.de_resultado) NOT LIKE '%A DINÂMICA DE PRODUÇÃO DE ANTICORPOS NA COVID-19 AINDA NÃO É BEM ESTABELECIDA%'
		AND to_char(e.dt_coleta, 'YYYY-MM') = '2020-12'
	GROUP BY idade
	ORDER BY casos_positivos DESC;

/****** Questão 2 ******/

-- 	Parte 1: rotina para criar senha automática para novos pacientes que serão inseridos na base

-- Criando função para gerar senha
CREATE EXTENSION pgcrypto;
CREATE OR REPLACE FUNCTION password_hash(passwordString TEXT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
	DECLARE MessageText TEXT;
		HintText TEXT;
	BEGIN
		IF passwordString IS NULL OR passwordString = '' THEN -- Conferindo se não é nulo
			RAISE EXCEPTION null_value_not_allowed USING MESSAGE = 'Senha nula', HINT = 'Insira uma senha para obter seu retorno criptografado';
		ELSE -- Retornando senha criptografada
			RETURN crypt(passwordString, gen_salt('md5'));
		END IF;
	EXCEPTION -- Imprimindo exceções encontradas
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS MessageText = MESSAGE_TEXT,	HintText = PG_EXCEPTION_HINT;
				RAISE NOTICE E'Erro: %\nMensagem: %\nDica: %',
				SQLSTATE, MessageText, HintText;
			RETURN NULL;
	END;
$$
-- DROP FUNCTION password_hash(TEXT);

-- Testando função com alguns casos de teste
DO $$
	BEGIN
		RAISE NOTICE 'Senha original: scc0541LabBD, Hash: %', password_hash('scc0541LabBD');
		RAISE NOTICE 'Senha original: covid19-Fapesp, Hash: %', password_hash('covid19-Fapesp');
		RAISE NOTICE 'Senha original: BˆrJgb, Hash: %', password_hash('BˆrJgb');
		RAISE NOTICE 'Senha original: Z67&*T, Hash: %', password_hash('Z67&*T');
		RAISE NOTICE 'Testando exeção com texto vazio: ';
		RAISE NOTICE '%', password_hash('');
		RAISE NOTICE 'Testando exeção com NULL: ';
		RAISE NOTICE '%', password_hash(NULL);
	END;
$$

-- Adicionando campo senha na tabela pacientes
ALTER TABLE pacientes
    ADD COLUMN senha text;
/*ALTER TABLE pacientes 
	DROP COLUMN senha;*/
	
-- Criando tabela temporária para testar solução
CREATE TABLE temp_pacientes AS 
	SELECT * FROM pacientes LIMIT 5;

-- Atualizando senhas da tabela temporária usando função de hash com os campos id_paciente, ic_sexo e aa_nascimento
UPDATE temp_pacientes
	SET senha = password_hash(CONCAT(id_paciente, ic_sexo, aa_nascimento));

-- Verificando atualização
SELECT senha as senha_gerada FROM temp_pacientes;

-- Testando autenticação
SELECT (senha = crypt(CONCAT('d9fec23b3820f93a961841d569db8cb5', 'F', '1974'), senha)) AS senhaConfere FROM temp_pacientes
	WHERE id_paciente = 'd9fec23b3820f93a961841d569db8cb5';
-- Retorno esperado: true
SELECT (senha = crypt('senha errada', senha)) AS senhaConfere FROM temp_pacientes
	WHERE id_paciente = 'd9fec23b3820f93a961841d569db8cb5';
-- Retorno esperado: false

-- Removendo tabela temporária
DROP TABLE temp_pacientes;

-- Atualizando senhas usando função hash
UPDATE pacientes
	SET senha = password_hash(CONCAT(id_paciente, ic_sexo, aa_nascimento));
	
-- Criando função que retorna trigger para criar senhas automaticamente após o paciente ser inserido
CREATE OR REPLACE FUNCTION setPwdTriggerFunction() 
	RETURNS TRIGGER 
	LANGUAGE PLPGSQL
	AS $$
	BEGIN
		NEW.senha = password_hash(CONCAT(NEW.id_paciente, NEW.ic_sexo, NEW.aa_nascimento));
		RETURN NEW;
	END;
	$$
-- DROP FUNCTION setPwdTriggerFunction();
	
-- Criando trigger que utilizará a função
CREATE TRIGGER setPwd
    BEFORE INSERT ON pacientes
    FOR EACH ROW
	EXECUTE PROCEDURE setPwdTriggerFunction();
-- DROP TRIGGER setPwd ON pacientes;
	
-- Testando trigger
INSERT INTO pacientes(
	id_paciente, ic_sexo, aa_nascimento, cd_pais, cd_uf, cd_municipio, cd_cepreduzido, id_hospital)
	VALUES ('novoPacienteTeste', 'M', 2000, 'BR', 'SP', 'MMMMM', 'CCCC', 0);
	
SELECT senha from pacientes WHERE id_paciente = 'novoPacienteTeste';

-- Testando autenticação
SELECT (senha = crypt(CONCAT('novoPacienteTeste', 'M', '2000'), senha)) AS senhaConfere FROM pacientes WHERE id_paciente = 'novoPacienteTeste';
-- Retorno esperado: true
SELECT (senha = crypt('senha errada', senha)) AS senhaConfere FROM pacientes WHERE id_paciente = 'novoPacienteTeste';
-- Retorno esperado: false

DELETE FROM pacientes
  WHERE id_paciente = 'novoPacienteTeste';

-- 	Parte 2: criar tabela LogAcesso (Campos necessários: data/hora, tipo de operação e tabela requisitada/alterada)

-- Criando tabela LogAcesso
CREATE TABLE LogAcesso
(
    id bigserial NOT NULL,
	autor char(50) NOT NULL,
    carimbo_de_tempo timestamp NOT NULL,
	operacao char(8) NOT NULL,
    tabela char(30) NOT NULL,
    PRIMARY KEY (id)
);
-- DROP TABLE LogAcesso;

/* 	Parte 3: rotina para criar logs na tabela LogAcesso quando os acessos e transações são realizados na base de dados
OBS: deve analisar três situações pertinentes para realizar a coleta da informação automaticamente */

-- Criando função que retorna trigger para inserir os logs na tabela LogAcesso
CREATE OR REPLACE FUNCTION newLogTriggerFunction() 
	RETURNS TRIGGER 
	LANGUAGE PLPGSQL
	AS $$
	BEGIN
		INSERT INTO LogAcesso(
			autor, carimbo_de_tempo, operacao, tabela)
			VALUES (USER, NOW(), TG_OP, TG_TABLE_NAME);
		RETURN NEW;
	END;
	$$
-- DROP FUNCTION newLogTriggerFunction();

-- Criando trigger para tabela LogPacientes que utilizará a função
CREATE TRIGGER LogPacientes
	AFTER INSERT OR UPDATE OR DELETE ON pacientes
	FOR EACH ROW
	EXECUTE PROCEDURE newLogTriggerFunction();
-- DROP TRIGGER LogPacientes ON pacientes;

-- Adicionando paciente para gerar log
INSERT INTO pacientes(
	id_paciente, ic_sexo, aa_nascimento, cd_pais, cd_uf, cd_municipio, cd_cepreduzido, id_hospital)
	VALUES ('testePacienteTrigger', 'F', 2000, 'BR', 'SP', 'MMMMM', 'CCCC', 1);

-- Criando trigger para tabela LogPacientes que utilizará a função
CREATE TRIGGER LogExames
	AFTER INSERT OR UPDATE OR DELETE ON exames
	FOR EACH ROW
	EXECUTE PROCEDURE newLogTriggerFunction();
-- DROP TRIGGER LogExames ON exames;
	
-- Adicionando exame para gerar log
INSERT INTO exames(
	id_exame, id_paciente, id_atendimento, dt_coleta, de_origem, de_exame, de_analito, de_resultado, cd_unidade, de_valor_referencia, id_hospital)
	VALUES (10000000, 'testePacienteTrigger', 'testeAtendimentoTrigger', '2020-07-19', 'HOSP', 'proteinuria', 'proteinuria', '1090', 'mL', '', 1);

-- Criando trigger para tabela LogPacientes que utilizará a função
CREATE TRIGGER LogDesfechos
	AFTER INSERT OR UPDATE OR DELETE ON desfechos
	FOR EACH ROW
	EXECUTE PROCEDURE newLogTriggerFunction();
-- DROP TRIGGER LogDesfechos ON desfechos;

-- Adicionando desfecho para gerar log
INSERT INTO desfechos(
	id_paciente, id_atendimento, dt_atendimento, de_tipo_atendimento, id_clinica, de_clinica, dt_desfecho, de_desfecho, id_hospital)
	VALUES ('testePacienteTrigger', 'testeAtendimentoTrigger', '2020-07-19', 'Ambulatorial', 11, 'Consulta', '2020-08-19', 'Alta a pedido', 1);

-- Deletando paciente teste, exame teste e desfecho teste para gerar novos logs
DELETE FROM desfechos WHERE id_paciente = 'testePacienteTrigger' AND id_atendimento = 'testeAtendimentoTrigger';
DELETE FROM exames WHERE id_exame = 10000000;
DELETE FROM pacientes WHERE id_paciente = 'testePacienteTrigger';

-- Vendo logs gerados
SELECT * FROM LogAcesso;

/****** Questão 3 ******/

/* 	Parte 1: Que tipo de informações relacionadas a COVID é possível recuperar analisando
os tipos de exames e analitos registrados? */

-- Pegando todos os tipos de exames de covid distintos
SELECT de_exame, COUNT(de_exame) AS quantidade FROM exames WHERE upper(de_exame) LIKE '%COVID%' GROUP BY de_exame;
/*
Output:
"covid-19-pcr para sars-cov-2, vários materiais (fleury)"	12160
"covid-19-sorologia igm e igg por quimiluminescência, soro"	5467
"covid-19-teste rápido (igm e igg), soro"	398
"covid-19 - pesquisa de anticorpos igg"	1518
"covid-19, anticorpos iga e igg, soro"	30
"covid teste líquor"	11
"teste rápido para covid-19 de ponta de dedo"	1
"teste rápido para sars-cov-2- pesquisa de anticorpos igg e igm (sorologia para covid-19)"	291
*/

/* Pergunta: se a diferença de porcentagem de casos positivos entre os exames for muito alta,
isso pode indicar que um exame tem mais falsos negativos que o outro? */
SELECT de_exame, COUNT(DISTINCT(id_paciente)) AS casos_positivos FROM exames
		WHERE de_exame = 'covid-19-pcr para sars-cov-2, vários materiais (fleury)' OR de_exame = 'covid-19-sorologia igm e igg por quimiluminescência, soro'
		AND (upper(de_resultado) LIKE '%POSITIVO%' 
				OR upper(de_resultado) LIKE 'DETECTADO%'
				OR upper(de_resultado) LIKE 'DETECTADOS ANTICORPOS%' 
				OR upper(de_resultado) LIKE 'REAGENTE%'
				OR upper(de_resultado) LIKE 'AMOSTRA REAGENTE%')
		AND upper(de_resultado) NOT LIKE '%A DINÂMICA DE PRODUÇÃO DE ANTICORPOS NA COVID-19 AINDA NÃO É BEM ESTABELECIDA%'
	GROUP BY de_exame;

/*
PCR: 12160 exames com 4583 positivos
Sorologia: 5467 exames com 373 positivos
	Com esses dados, constatamos que o exame de PCR acusou positivo para covid em 37,6% dos casos e o exame de sorologia apenas em 6%.
Visto isso, podemos nos atentar a duas possibilidades, o exame de Sorologia está sujeito a apresentar muitos falsos negativos ou
os pacientes realizaram o exame sem respeitar o tempo mínimo de 7 dias após os sintomas para realizá-lo pois esse exame não detecta o vírus
e sim a presença de anticorpos.
*/

/* 	Parte 2: Analisando a quantidade de registros de um determinado exame de COVID em
relação a data de coleta ou período (por exemplo semanal), é possível indicar tendências de alta
e/ou baixa que auxiliariam a especialistas médicos em analises futuras? */

-- Casos positivos agrupados e ordenados por mês a fim de identificar altas e baixas, o ideal seria ter os dados de 2021 para comparar. 
SELECT EXTRACT(MONTH FROM dt_coleta) as mes, COUNT(DISTINCT(id_paciente)) AS casos_positivos FROM exames
		WHERE upper(de_exame) LIKE '%COVID%'
		AND (upper(de_resultado) LIKE '%POSITIVO%' 
				OR upper(de_resultado) LIKE 'DETECTADO%'
				OR upper(de_resultado) LIKE 'DETECTADOS ANTICORPOS%' 
				OR upper(de_resultado) LIKE 'REAGENTE%'
				OR upper(de_resultado) LIKE 'AMOSTRA REAGENTE%')
		AND upper(de_resultado) NOT LIKE '%A DINÂMICA DE PRODUÇÃO DE ANTICORPOS NA COVID-19 AINDA NÃO É BEM ESTABELECIDA%'
	GROUP BY mes
	ORDER BY mes;

/* 	Parte 3: Que tipo de informações adicionais, em versões futuras da base de dados, poderiam
ser coletadas em novos hospitais para melhorar a qualidade dos dados analisados? */

/* Criando tabela VacinacaoCovid com campo id_paciente e vacina,
assim será possível saber quais pacientes foram vacinados para covid, qual foi a vacina e qual dose */
CREATE TABLE VacinacaoCovid
(
    id_paciente TEXT NOT NULL,
	vacina TEXT NOT NULL,
	dose CHAR NOT NULL,
    CONSTRAINT vacina_id_paciente_fkey FOREIGN KEY (id_paciente)
        REFERENCES pacientes (id_paciente) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE
);
-- DROP TABLE VacinacaoCovid;

/* Criando tabela VacinacaoCovid com campo id_exame e cepa,
nessa tabela serão inseridos apenas ids de exame que confirmaram positivo para covid,
com o id do exame podemos ter acesso a todas as informações relacionadas ao exame inclusive do paciente*/
CREATE TABLE CepaCovid
(
	id_exame INTEGER NOT NULL,
	cepa TEXT NOT NULL,
    CONSTRAINT cepa_id_exame_fkey FOREIGN KEY (id_exame)
        REFERENCES exames (id_exame) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE
);
-- DROP TABLE CepaCovid;

