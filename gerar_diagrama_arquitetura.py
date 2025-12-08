"""
Script para gerar diagrama de arquitetura do sistema de correção automática de erros

Requisitos:
    pip install matplotlib

Execute:
    python gerar_diagrama_arquitetura.py
"""
try:
    import matplotlib.pyplot as plt
    import matplotlib.patches as mpatches
    from matplotlib.patches import FancyBboxPatch, FancyArrowPatch, Circle, Rectangle
    import matplotlib.patheffects as path_effects
except ImportError:
    print("ERRO: matplotlib não está instalado.")
    print("Instale com: pip install matplotlib")
    exit(1)

# Configuração da figura
fig, ax = plt.subplots(1, 1, figsize=(20, 14))
ax.set_xlim(0, 20)
ax.set_ylim(0, 14)
ax.axis('off')

# Cores
color_github = '#24292e'
color_aws = '#FF9900'
color_eks = '#FF6B6B'
color_s3 = '#4ECDC4'
color_cloudwatch = '#FFA500'
color_mongodb = '#47A248'
color_prometheus = '#E6522C'
color_grafana = '#F46800'
color_app = '#4A90E2'
color_ml = '#9B59B6'
color_net = '#95A5A6'

# Função para criar caixas arredondadas
def create_box(x, y, width, height, text, color, text_color='white', fontsize=10):
    box = FancyBboxPatch((x, y), width, height,
                         boxstyle="round,pad=0.1",
                         edgecolor='black',
                         facecolor=color,
                         linewidth=2)
    ax.add_patch(box)
    ax.text(x + width/2, y + height/2, text,
            ha='center', va='center',
            fontsize=fontsize, fontweight='bold',
            color=text_color,
            path_effects=[path_effects.withStroke(linewidth=3, foreground='white')])

# Função para criar setas
def create_arrow(x1, y1, x2, y2, color='black', style='->', linewidth=2, label=''):
    arrow = FancyArrowPatch((x1, y1), (x2, y2),
                           arrowstyle=style,
                           color=color,
                           linewidth=linewidth,
                           mutation_scale=20)
    ax.add_patch(arrow)
    if label:
        mid_x, mid_y = (x1 + x2) / 2, (y1 + y2) / 2
        ax.text(mid_x, mid_y + 0.3, label,
                ha='center', fontsize=8, color=color, fontweight='bold',
                bbox=dict(boxstyle='round,pad=0.3', facecolor='white', alpha=0.8))

# Título
ax.text(10, 13.5, 'Sistema de Correção Automática de Erros com ML', 
        ha='center', fontsize=20, fontweight='bold')

# === CAMADA DE DESENVOLVIMENTO ===
ax.text(10, 12.5, 'DESENVOLVIMENTO & CI/CD', ha='center', fontsize=14, 
        fontweight='bold', style='italic', color='#2C3E50')
create_box(1, 11, 3, 1, 'GitHub\nRepository', color_github, fontsize=9)
create_box(5, 11, 3, 1, 'GitHub\nActions', color_github, fontsize=9)
create_box(9, 11, 3, 1, 'Terraform\n(IaC)', color_aws, fontsize=9)
create_box(13, 11, 3, 1, 'Helm\nCharts', color_eks, fontsize=9)

# Setas CI/CD
create_arrow(4, 11.5, 5, 11.5, color_github, label='Push')
create_arrow(8, 11.5, 9, 11.5, color_aws, label='Deploy')
create_arrow(12, 11.5, 13, 11.5, color_eks, label='Deploy')

# === CAMADA AWS INFRAESTRUTURA ===
ax.text(10, 9.5, 'INFRAESTRUTURA AWS', ha='center', fontsize=14, 
        fontweight='bold', style='italic', color='#2C3E50')

# VPC
create_box(0.5, 7.5, 19, 1.5, 'VPC (Virtual Private Cloud)', color_net, 
           text_color='black', fontsize=11)

# EKS Cluster
create_box(1, 6.5, 4, 1, 'EKS Cluster\n(Kubernetes)', color_eks, fontsize=9)

# ECR
create_box(6, 6.5, 2.5, 1, 'ECR\nContainer\nRegistry', color_aws, fontsize=8)

# S3 Buckets
create_box(9.5, 6.5, 2.5, 1, 'S3\nLogs & ML\nArtifacts', color_s3, fontsize=8)

# CloudWatch
create_box(13, 6.5, 2.5, 1, 'CloudWatch\nLogs', color_cloudwatch, fontsize=8)

# SSM Parameter Store
create_box(16.5, 6.5, 2.5, 1, 'SSM\nSecrets', color_aws, fontsize=8)

# === CAMADA KUBERNETES ===
ax.text(10, 5.5, 'SERVIÇOS NO EKS', ha='center', fontsize=14, 
        fontweight='bold', style='italic', color='#2C3E50')

# App Service
create_box(1, 3.5, 3.5, 1.5, 'app-service\n(FastAPI)\nPOST /errors\nPOST /feedback', 
           color_app, fontsize=9)

# ML Service
create_box(5.5, 3.5, 3.5, 1.5, 'ml-service\n(FastAPI)\nPOST /predict\nInference', 
           color_ml, fontsize=9)

# Observability Stack
create_box(10, 3.5, 3.5, 1.5, 'Observability\nPrometheus\nGrafana\nOTel Collector', 
           color_prometheus, fontsize=9)

# MongoDB
create_box(14.5, 3.5, 3.5, 1.5, 'MongoDB\nDatabase\nErrors & Feedback', 
           color_mongodb, fontsize=9)

# === CAMADA ML TRAINING ===
ax.text(10, 2, 'PIPELINE DE TREINAMENTO', ha='center', fontsize=14, 
        fontweight='bold', style='italic', color='#2C3E50')
create_box(5, 0.5, 4, 1, 'ml-training\nPipeline\n(Periodic)', color_ml, fontsize=9)
create_box(11, 0.5, 4, 1, 'Model Training\nLightGBM/Sklearn', color_ml, fontsize=9)

# === FLUXOS DE DADOS ===

# Fluxo principal: Erro -> App -> ML -> Sugestão
create_arrow(2.75, 4.5, 2.75, 5.5, color_app, style='->', linewidth=3, label='1. Erro')
create_arrow(2.75, 5.5, 7.25, 5.5, color_app, style='->', linewidth=3, label='2. Consulta ML')
create_arrow(7.25, 5.5, 7.25, 4.5, color_ml, style='->', linewidth=3, label='3. Sugestão')
create_arrow(2.75, 3.5, 16.25, 3.5, color_mongodb, style='->', linewidth=2, label='4. Salvar')

# Fluxo de logs
create_arrow(2.75, 3.5, 10.75, 3.5, color_s3, style='->', linewidth=2, label='Logs')
create_arrow(2.75, 3.5, 13.5, 3.5, color_cloudwatch, style='->', linewidth=2, label='Logs')

# Fluxo de feedback
create_arrow(16.25, 4.5, 16.25, 5.5, color_mongodb, style='->', linewidth=2, label='5. Feedback')
create_arrow(16.25, 5.5, 10.75, 5.5, color_mongodb, style='->', linewidth=2, label='6. Treinar')

# Fluxo de treinamento
create_arrow(7, 1, 7, 3.5, color_ml, style='->', linewidth=2, label='7. Atualizar Modelo')
create_arrow(13, 1, 13, 3.5, color_ml, style='->', linewidth=2, label='Modelo')

# Fluxo CI/CD
create_arrow(6.5, 11.5, 6.5, 7.5, color_github, style='->', linewidth=2, label='Build & Push')
create_arrow(2.5, 11.5, 3, 7.5, color_github, style='->', linewidth=2, label='Deploy')

# Observabilidade
create_arrow(11.75, 4.5, 11.75, 5.5, color_prometheus, style='->', linewidth=2, label='Métricas')
create_arrow(11.75, 5.5, 13.5, 5.5, color_prometheus, style='->', linewidth=2, label='Logs')

# Legenda
legend_elements = [
    mpatches.Patch(color=color_github, label='GitHub/CI-CD'),
    mpatches.Patch(color=color_aws, label='AWS Services'),
    mpatches.Patch(color=color_eks, label='Kubernetes/EKS'),
    mpatches.Patch(color=color_app, label='App Service'),
    mpatches.Patch(color=color_ml, label='ML Service'),
    mpatches.Patch(color=color_mongodb, label='MongoDB'),
    mpatches.Patch(color=color_prometheus, label='Observability'),
    mpatches.Patch(color=color_s3, label='S3 Storage'),
    mpatches.Patch(color=color_cloudwatch, label='CloudWatch'),
]

ax.legend(handles=legend_elements, loc='upper right', fontsize=9, 
          framealpha=0.9, title='Componentes', title_fontsize=10)

# Salvar como JPEG
plt.tight_layout()
plt.savefig('arquitetura_sistema.jpg', dpi=300, format='jpeg', bbox_inches='tight', 
            facecolor='white', edgecolor='none')
print("Diagrama de arquitetura salvo como 'arquitetura_sistema.jpg'")
plt.close()

