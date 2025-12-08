# Treinamento de modelo

Fontes de dados:
- Logs em S3 (`logs` bucket) + labels em MongoDB

Passos : ***EM ANDAMENTO
1) Extrair features de logs/traces (ex: TF-IDF de mensagens, códigos de erro, métricas).
2) Treinar classificador (ex: LightGBM/Sklearn) ou modelo generativo para sugestão de correção.
3) Salvar artefatos no bucket `ml_artifacts` e registrar versão.
4) Atualizar o `ml-service` para carregar a nova versão (env `MODEL_S3_BUCKET` + chave do modelo).

Automação:
- Use pipeline ex: GitHub Actions  para treino sob demanda.
- Versione datasets e modelos .


