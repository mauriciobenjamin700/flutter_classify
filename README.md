# Flutter Classify 🤖📱

Um aplicativo Flutter para classificação de imagens usando modelos TensorFlow Lite. Este projeto demonstra como integrar modelos de machine learning em aplicações móveis para classificação de imagens em tempo real.

## 📋 Visão Geral

O **Flutter Classify** é uma implementação completa de um sistema de classificação de imagens que utiliza:

- **TensorFlow Lite** para inferência eficiente em dispositivos móveis
- **Flutter** para interface multiplataforma
- **Arquitetura modular** para fácil manutenção e extensibilidade

### 🎯 Funcionalidades

- ✅ Carregamento de modelos TFLite otimizados para mobile
- ✅ Pré-processamento automático de imagens
- ✅ Inferência em tempo real
- ✅ Interface intuitiva para seleção de imagens
- ✅ Exibição de resultados com níveis de confiança
- ✅ Suporte a múltiplas classes (gatos e cachorros no exemplo)

---

## 🏗️ Estrutura do Projeto

```bash
lib/
├── main.dart                 # Ponto de entrada da aplicação
├── core/                     # Lógica central do sistema
│   ├── constants.dart        # Constantes e configurações
│   ├── tflite.dart          # Handler do TensorFlow Lite
│   └── image_handler.dart    # Processamento de imagens
├── pages/                    # Telas da aplicação
│   └── home.dart            # Tela principal
├── services/                 # Serviços de classificação
│   └── image_classifier.dart # Service de classificação
├── widgets/                  # Componentes reutilizáveis
│   └── image_gallery.dart   # Galeria de imagens
└── schemas/                  # Modelos de dados
    └── result.dart          # Estrutura do resultado

assets/
├── models/                   # Modelos TensorFlow Lite
│   ├── best_float16.tflite  # Modelo otimizado
│   └── labels.txt           # Labels das classes
├── cat1.png                 # Imagens de exemplo
├── cat2.png
├── dog1.png
└── dog2.png
```

---

## 🔄 Fluxo de Processamento

### 1. **Carregamento do Modelo**

```dart
// Inicialização do TFLiteHandler
final tfliteHandler = TFLiteHandler(
  modelPath: 'assets/models/best_float16.tflite',
  labelsPath: 'assets/labels.txt',
);

await tfliteHandler.loadModel();
```

**O que acontece:**

- Carrega o modelo TFLite dos assets
- Lê e processa o arquivo de labels
- Inicializa o interpretador TensorFlow Lite
- Valida as dimensões de entrada e saída

### 2. **Seleção da Imagem**

O usuário seleciona uma imagem através da interface:

- Galeria mostra imagens pré-definidas (cat1, cat2, dog1, dog2)
- Interface responsiva com feedback visual
- Loading indicator durante processamento

### 3. **Pré-processamento da Imagem**

```dart
// Processo de preparação da imagem
final imageBytes = await ImageHandler.loadImage(imagePath);
final originalImage = img.decodeImage(imageBytes);
final resizedImage = img.copyResize(originalImage, width: 224, height: 224);
```

**Etapas do pré-processamento:**

1. **Carregamento**: Lê a imagem dos assets ou arquivo local
2. **Decodificação**: Converte bytes em objeto Image
3. **Redimensionamento**: Ajusta para dimensões do modelo (224x224)
4. **Normalização**: Converte pixels RGB para valores 0.0-1.0
5. **Formatação do Tensor**: Organiza dados no formato [1, 224, 224, 3]

```dart
// Conversão para tensor usando iterador de pixels
for (final pixel in resizedImage) {
  tensor[0][y][x][0] = pixel.r / pixel.maxChannelValue; // Red
  tensor[0][y][x][1] = pixel.g / pixel.maxChannelValue; // Green
  tensor[0][y][x][2] = pixel.b / pixel.maxChannelValue; // Blue
}
```

---

## 🧠 Formato dos Dados do Modelo

### **Entrada (Input)**

- **Formato**: `[batch_size, height, width, channels]`
- **Dimensões**: `[1, 224, 224, 3]`
- **Tipo**: `Float32`
- **Range**: `0.0 - 1.0` (normalizado)
- **Ordem dos canais**: RGB

### **Saída (Output)**

- **Formato**: `[batch_size, num_classes]`
- **Dimensões**: `[1, 2]` (para gato/cachorro)
- **Tipo**: `Float32`
- **Range**: `0.0 - 1.0` (probabilidades)
- **Processamento**: Softmax já aplicado pelo modelo

---

## ⚡ Processo de Inferência

### 1. **Execução do Modelo**

```dart
// Preparação do tensor de saída
final outputShape = _interpreter!.getOutputTensor(0).shape; // [1, 2]
final output = List.generate(
  outputShape[0], // batch_size = 1
  (index) => List<double>.filled(outputShape[1], 0.0), // 2 classes
);

// Execução da inferência
_interpreter!.run(inputTensor, output);
```

### 2. **Interpretação dos Resultados**

```dart
final probabilities = output[0]; // [prob_gato, prob_cachorro]

// Exemplo de saída: [0.02, 0.98]
// Interpretação: 2% gato, 98% cachorro
```

**O modelo retorna:**

- Probabilidades já normalizadas (soma = 1.0)
- Softmax aplicado internamente
- Valores diretos podem ser usados como confiança

---

## 📊 Formato do Resultado

### **Estrutura PredictionResult**

```dart
class PredictionResult {
  final int id;           // Índice da classe (0 ou 1)
  final String label;     // Nome da classe ("Cat" ou "Dog")
  final double confidence; // Nível de confiança (0.0 - 1.0)
}
```

### **Exemplo de Resultado**

```dart
PredictionResult(
  id: 1,
  label: "Dog", 
  confidence: 0.98
)
```

**Significado:**

- Classe 1 = "Dog" (conforme labels.txt)
- Confiança de 98%
- Resultado com alta certeza

---

## 🖥️ Exibição na Interface

### **Componentes da UI**

1. **Status do Modelo**

   ```dart
   Container(
     decoration: BoxDecoration(color: Colors.green.shade100),
     child: Text('Modelo carregado'),
   )
   ```

2. **Galeria de Imagens**

   ```dart
   GridView.builder(
     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
       crossAxisCount: 2,
     ),
     itemBuilder: (context, index) => ImageCard(),
   )
   ```

3. **Resultado da Classificação**

   ```dart
   Text('Classe: ${result.label}'),
   Text('Confiança: ${(result.confidence * 100).toStringAsFixed(1)}%'),
   LinearProgressIndicator(value: result.confidence),
   ```

### **Fluxo da Interface**

1. **Estado Inicial**: Mostra galeria de imagens disponíveis
2. **Seleção**: Usuário toca em uma imagem
3. **Loading**: Indicador visual durante processamento
4. **Resultado**: Exibe classe predita e nível de confiança
5. **Feedback Visual**: Cores e ícones baseados na confiança

---

## 🚀 Como Executar

### **Pré-requisitos**

- Flutter SDK 3.8.1+
- Android Studio ou VS Code
- Emulador Android ou dispositivo físico

### **Instalação**

1. **Clone o repositório**

   ```bash
   git clone https://github.com/mauriciobenjamin700/flutter_classify.git
   cd flutter_classify
   ```

2. **Instale as dependências**

   ```bash
   flutter pub get
   ```

3. **Execute o aplicativo**

   ```bash
   flutter run
   ```

---

## 📦 Dependências Principais

```yaml
dependencies:
  flutter:
    sdk: flutter
  tflite_flutter: ^0.11.0  # TensorFlow Lite para Flutter
  image: ^4.1.7             # Processamento de imagens
  cupertino_icons: ^1.0.8   # Ícones iOS
```

---

## 🔧 Personalização

### **Adicionando Novas Classes**

1. **Retreine o modelo** com novas classes
2. **Atualize labels.txt** com os novos nomes
3. **Ajuste as constantes** em `core/constants.dart`
4. **Adicione imagens de exemplo** nos assets

### **Alterando Dimensões do Modelo**

1. **Modifique as constantes** de largura/altura
2. **Ajuste o pré-processamento** no ImageHandler
3. **Teste com imagens** de diferentes resoluções

---

## 📈 Performance

### **Otimizações Implementadas**

- ✅ **Modelo Float16**: Reduz tamanho e aumenta velocidade
- ✅ **Lazy Loading**: Carrega modelo apenas quando necessário
- ✅ **Cache de Tensor**: Reutiliza estruturas de dados
- ✅ **Processamento Eficiente**: Usa iteradores nativos da lib image

### **Métricas Típicas**

- **Tempo de carregamento**: ~500ms (primeira vez)
- **Tempo de inferência**: ~100-300ms por imagem
- **Uso de memória**: ~50-100MB
- **Precisão**: Depende do modelo treinado

---

## 🐛 Troubleshooting

### **Problemas Comuns**

1. **"Asset not found"**
   - Verifique se o modelo está em `assets/models/`
   - Confirme se `pubspec.yaml` inclui os assets

2. **"Shape mismatch"**
   - Verifique dimensões do modelo vs. código
   - Use `getModelInfo()` para debug

3. **"Low confidence"**
   - Modelo pode precisar de retreinamento
   - Verifique qualidade das imagens de entrada

---

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## 👥 Contribuição

Contribuições são bem-vindas! Por favor:

1. Faça um fork do projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Abra um Pull Request

---

## 📞 Contato

**Mauricio Benjamin**:

- GitHub: [@mauriciobenjamin700](https://github.com/mauriciobenjamin700)
- Email: [mauriciobenjamin700@gmail.com](mauriciobenjamin700@gmail.com)

---

**⭐ Se este projeto foi útil, considere dar uma estrela no repositório!**
