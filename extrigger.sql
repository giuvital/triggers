CREATE DATABASE comercio	
go
USE comercio

CREATE TABLE produto(
codigo INT NOT NULL,
nome VARCHAR(50) NOT NULL,
descricao VARCHAR,
valor DECIMAL(7,2) NOT NULL,
PRIMARY KEY (codigo))

CREATE TABLE estoque(
codigo_produto INT NOT NULL,
qtd_estoque INT NOT NULL,
estoque_minimo INT NOT NULL,
PRIMARY KEY (codigo_produto))

CREATE TABLE venda(
nota_fiscal INT NOT NULL,
codigo_produto INT NOT NULL,
quantidade INT NOT NULL,
PRIMARY KEY (nota_fiscal),
FOREIGN KEY (codigo_produto) REFERENCES produto (codigo))

CREATE TRIGGER t_venda
ON venda
AFTER INSERT
AS
BEGIN
    DECLARE 
	@qtd_produto_estoque INT, 
	@qtd_vendida INT,
	@codigo_produto_vendido INT,
	@qtd_apos_venda INT

	SET @codigo_produto_vendido = (SELECT codigo_produto FROM inserted)
	SET @qtd_vendida = (SELECT quantidade FROM inserted)
	SET @qtd_produto_estoque = (SELECT e.qtd_estoque FROM estoque e WHERE e.codigo_produto = @codigo_produto_vendido)
	
	IF(@qtd_produto_estoque < @qtd_vendida)
	BEGIN
	   ROLLBACK TRANSACTION
		RAISERROR('O estoque est� a baixo da quantidade pedida', 16, 1)
	END
	ELSE
	BEGIN
	   SET @qtd_apos_venda = @qtd_produto_estoque - @qtd_vendida;
	   IF(@qtd_apos_venda < (select estoque_minimo from estoque where codigo_produto = @codigo_produto_vendido))
	   BEGIN
	      IF(@qtd_apos_venda < (select estoque_minimo from estoque where codigo_produto = @codigo_produto_vendido) AND @qtd_produto_estoque >= (select estoque_minimo from estoque where codigo_produto = @codigo_produto_vendido))
	      BEGIN
	        PRINT('Apos a venda o estoque estar� abaixo do n�vel adequado.')
	      END
	      ELSE
	      BEGIN
	        PRINT('O estoque esta abaixo do n�vel adequado.')
	      END
	   END

	   UPDATE estoque SET qtd_estoque = qtd_estoque - @qtd_vendida WHERE codigo_produto = @codigo_produto_vendido
	END

END

CREATE FUNCTION fn_nota_fiscal(@num_nota INT)
RETURNS @table TABLE (
nota_fiscal INT,
codigo_produto INT,
nome_produto VARCHAR(50),
descricao_produto VARCHAR,
valor_unitario DECIMAL(7,2),
quantidade INT,
valor_total DECIMAL(7,2))
AS
BEGIN
	INSERT INTO @table (nota_fiscal, codigo_produto, nome_produto, descricao_produto, valor_unitario, quantidade, valor_total)
		SELECT v.nota_fiscal, v.codigo_produto, p.nome, p.descricao, p.valor, v.quantidade, (p.valor * v.quantidade) as valor_total FROM venda v, produto p, estoque e WHERE v.codigo_produto = p.codigo AND v.codigo_produto = e.codigo_produto AND v.nota_fiscal = @num_nota
 
	RETURN
END


INSERT INTO produto VALUES
(1,'TV',null,3000),
(2,'Celular',null,1000)

INSERT INTO estoque VALUES
(1,10,3),
(2,30,8)

SELECT * FROM produto
SELECT * FROM estoque
SELECT * FROM venda

INSERT INTO venda VALUES
(1118,2,10)


SELECT * FROM fn_nota_fiscal(1111)