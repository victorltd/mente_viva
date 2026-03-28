// lib/features/legal/screens/terms_screen.dart

import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../config/constants/legal_constants.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termos de Uso'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Termos de Uso',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              'Versão ${LegalConstants.termsVersion} • '
              'Atualizado em ${LegalConstants.lastUpdated}',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const SizedBox(height: AppSizes.lg),

            _buildSection(
              context,
              title: '1. Aceitação dos Termos',
              content:
                  'Ao acessar e usar o aplicativo MenteViva, você concorda em '
                  'cumprir e estar vinculado a estes Termos de Uso. Se você não '
                  'concordar com qualquer parte destes termos, não poderá usar '
                  'nossos serviços.',
            ),

            _buildSection(
              context,
              title: '2. Descrição do Serviço',
              content:
                  'O MenteViva é uma plataforma tecnológica que conecta psicólogos '
                  'e seus pacientes, oferecendo ferramentas de apoio ao acompanhamento '
                  'terapêutico, incluindo check-ins emocionais, tarefas terapêuticas '
                  'e acompanhamento de evolução.\n\n'
                  '${LegalConstants.appDisclaimer}',
            ),

            _buildSection(
              context,
              title: '3. Não é Serviço de Emergência',
              content:
                  'O MenteViva NÃO É um serviço de emergência em saúde mental. '
                  'Em caso de crise, risco de suicídio ou necessidade de atendimento '
                  'imediato, você deve:\n\n'
                  '• Ligar para o CVV: 188 (24 horas, gratuito)\n'
                  '• Procurar o pronto-socorro mais próximo\n'
                  '• Ligar para o SAMU: 192\n\n'
                  'O aplicativo não monitora suas informações em tempo real e '
                  'não pode fornecer atendimento de emergência.',
            ),

            _buildSection(
              context,
              title: '4. Cadastro e Conta',
              content:
                  'Para usar o MenteViva, você deve criar uma conta fornecendo '
                  'informações precisas e atualizadas. Você é responsável por:\n\n'
                  '• Manter a confidencialidade de sua senha\n'
                  '• Todas as atividades realizadas em sua conta\n'
                  '• Notificar imediatamente qualquer uso não autorizado',
            ),

            _buildSection(
              context,
              title: '5. Responsabilidades do Psicólogo',
              content:
                  'Os psicólogos que utilizam a plataforma declaram:\n\n'
                  '• Possuir registro ativo no CRP\n'
                  '• Estar cadastrados no e-Psi para atendimento online\n'
                  '• Seguir as diretrizes da Resolução CFP nº 11/2018\n'
                  '• Manter sigilo profissional conforme Código de Ética\n'
                  '• Ser responsáveis pelo tratamento e conduta profissional\n\n'
                  '${LegalConstants.cfpLimitations}',
            ),

            _buildSection(
              context,
              title: '6. Responsabilidades do Paciente',
              content:
                  'O paciente concorda em:\n\n'
                  '• Fornecer informações verdadeiras nos check-ins\n'
                  '• Não usar o app para situações de emergência\n'
                  '• Comunicar ao psicólogo qualquer agravamento\n'
                  '• Manter comunicação respeitosa na plataforma',
            ),

            _buildSection(
              context,
              title: '7. Privacidade e Dados',
              content:
                  'O tratamento dos seus dados pessoais é regido pela nossa '
                  'Política de Privacidade, em conformidade com a Lei Geral de '
                  'Proteção de Dados (LGPD - Lei nº 13.709/2018).\n\n'
                  '${LegalConstants.confidentialityNotice}',
            ),

            _buildSection(
              context,
              title: '8. Propriedade Intelectual',
              content:
                  'Todo o conteúdo do aplicativo, incluindo mas não limitado a '
                  'textos, gráficos, logos, ícones, imagens e software, é de '
                  'propriedade do MenteViva ou de seus licenciadores e está '
                  'protegido por leis de direitos autorais.',
            ),

            _buildSection(
              context,
              title: '9. Limitação de Responsabilidade',
              content:
                  'O MenteViva não se responsabiliza por:\n\n'
                  '• Decisões tomadas com base nas informações do app\n'
                  '• Interrupções técnicas ou indisponibilidade\n'
                  '• Condutas de psicólogos ou pacientes\n'
                  '• Danos indiretos, incidentais ou consequenciais\n\n'
                  'O tratamento psicológico é de responsabilidade do '
                  'profissional habilitado.',
            ),

            _buildSection(
              context,
              title: '10. Modificações',
              content:
                  'Reservamo-nos o direito de modificar estes Termos a qualquer '
                  'momento. Você será notificado sobre alterações significativas '
                  'e precisará aceitar os novos termos para continuar usando '
                  'o serviço.',
            ),

            _buildSection(
              context,
              title: '11. Rescisão',
              content:
                  'Você pode encerrar sua conta a qualquer momento através das '
                  'configurações do aplicativo. Podemos suspender ou encerrar '
                  'sua conta em caso de violação destes Termos.',
            ),

            _buildSection(
              context,
              title: '12. Lei Aplicável',
              content:
                  'Estes Termos são regidos pelas leis da República Federativa '
                  'do Brasil. Qualquer disputa será submetida ao foro da comarca '
                  'de [Cidade/Estado], com exclusão de qualquer outro.',
            ),

            _buildSection(
              context,
              title: '13. Contato',
              content:
                  'Para dúvidas sobre estes Termos:\n\n'
                  '📧 ${LegalConstants.companyEmail}\n'
                  '📧 ${LegalConstants.supportEmail}',
            ),

            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}