// Script para gerar ícone do app como PNG
// Execute: dart tools/generate_app_icon.dart

import 'dart:io';
import 'dart:typed_data';

void main() async {
  // Como não podemos gerar PNG diretamente sem bibliotecas,
  // vou instruir o usuário a usar um gerador online ou criar manualmente
  
  print('═' * 60);
  print('📱 GERADOR DE ÍCONE - MenteViva');
  print('═' * 60);
  print('');
  print('Para gerar o ícone do app, siga estes passos:');
  print('');
  print('1. Acesse: https://www.svgviewer.dev/svg-to-png');
  print('2. Cole o conteúdo do arquivo: assets/icons/app_icon.svg');
  print('3. Configure para 1024x1024 pixels');
  print('4. Salve como: assets/icons/app_icon.png');
  print('');
  print('OU use o site: https://appicon.co');
  print('- Upload da imagem');
  print('- Ele gera automaticamente todos os tamanhos necessários');
  print('');
  print('═' * 60);
}
