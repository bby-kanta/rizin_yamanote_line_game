// 初期化関数を定義（重複実行防止）
function initializeFighterFeatures() {
  if (!document.getElementById('features-container')) {
    return; // 特徴管理ページでない場合は何もしない
  }
  
  // 既に初期化済みの場合は何もしない
  if (document.body.dataset.fighterFeaturesInitialized === 'true') {
    return;
  }
  
  document.body.dataset.fighterFeaturesInitialized = 'true';

  let featureIndex = 1;

  // カテゴリオプションを動的に取得
  function getCategoryOptions() {
    const firstCategorySelect = document.querySelector('select[name$="[category_id]"]');
    if (firstCategorySelect) {
      return firstCategorySelect.innerHTML;
    }
    return '<option value="">カテゴリを選択</option>';
  }

  // 固定のカテゴリオプション（バックアップ用）
  function getStaticCategoryOptions() {
    return `
      <option value="">カテゴリを選択</option>
      <option value="1">階級</option>
      <option value="2">戦績</option>
      <option value="3">来歴</option>
      <option value="4">通称</option>
      <option value="5">所属</option>
      <option value="6">ファイトスタイル</option>
      <option value="7">その他</option>
    `;
  }

  // 特徴追加ボタン
  const addFeatureBtn = document.getElementById('add-feature');
  if (addFeatureBtn) {
    addFeatureBtn.addEventListener('click', function() {
      const container = document.getElementById('features-container');
      const categoryOptions = getCategoryOptions();
      
      const newRow = document.createElement('div');
      newRow.className = 'feature-row mb-3';
      newRow.innerHTML = `
        <div class="row">
          <div class="col-md-3">
            <select name="features[${featureIndex}][category_id]" class="form-select" required>
              ${categoryOptions}
            </select>
          </div>
          <div class="col-md-2">
            <select name="features[${featureIndex}][level]" class="form-select" required>
              <option value="">レベル</option>
              <option value="1">1（具体性が高い）</option>
              <option value="2">2（普通）</option>
              <option value="3">3（抽象度が高い）</option>
            </select>
          </div>
          <div class="col-md-6">
            <input type="text" name="features[${featureIndex}][feature]" class="form-control" placeholder="特徴を入力">
          </div>
          <div class="col-md-1">
            <button type="button" class="btn btn-danger remove-feature">削除</button>
          </div>
        </div>
      `;
      container.appendChild(newRow);
      featureIndex++;
    });
  }

  // 特徴削除（イベント委任）
  const container = document.getElementById('features-container');
  if (container) {
    container.addEventListener('click', function(e) {
      if (e.target.classList.contains('remove-feature')) {
        e.target.closest('.feature-row').remove();
      }
    });
  }

  // 全クリアボタン
  const clearAllBtn = document.getElementById('clear-all');
  if (clearAllBtn) {
    clearAllBtn.addEventListener('click', function() {
      if (confirm('全ての入力内容をクリアしますか？')) {
        const categoryOptions = getCategoryOptions();
        container.innerHTML = `
          <div class="feature-row mb-3">
            <div class="row">
              <div class="col-md-3">
                <select name="features[0][category_id]" class="form-select" required>
                  ${categoryOptions}
                </select>
              </div>
              <div class="col-md-2">
                <select name="features[0][level]" class="form-select" required>
                  <option value="">レベル</option>
                  <option value="1">1（具体性が高い）</option>
                  <option value="2">2（普通）</option>
                  <option value="3">3（抽象度が高い）</option>
                </select>
              </div>
              <div class="col-md-6">
                <input type="text" name="features[0][feature]" class="form-control" placeholder="特徴を入力">
              </div>
              <div class="col-md-1">
                <button type="button" class="btn btn-danger remove-feature">削除</button>
              </div>
            </div>
          </div>
        `;
        featureIndex = 1;
      }
    });
  }

  // AI生成ボタン
  const generateBtn = document.getElementById('generate-ai-features');
  if (generateBtn) {
    generateBtn.addEventListener('click', function() {
      const loadingDiv = document.getElementById('ai-loading');
      const button = this;
      const originalText = button.innerHTML;
      const fighterId = button.dataset.fighterId;
      
      if (!fighterId) {
        alert('選手IDが見つかりません');
        return;
      }
      
      // ローディング表示
      if (loadingDiv) {
        loadingDiv.style.display = 'block';
      }
      button.disabled = true;
      button.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>生成中...';

      const csrfToken = document.querySelector('meta[name="csrf-token"]');
      if (!csrfToken) {
        alert('CSRF token not found');
        return;
      }

      console.log('Sending AI generation request for fighter:', fighterId);

      fetch(`/fighters/${fighterId}/generate_ai_features`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken.content
        }
      })
      .then(response => {
        console.log('Response status:', response.status);
        return response.json();
      })
      .then(data => {
        console.log('Response data:', data);
        console.log('data.success:', data.success);
        console.log('data.success type:', typeof data.success);
        console.log('data.success === true:', data.success === true);
        if (data.success) {
          console.log('Calling populateFeatures with:', data.features);
          populateFeatures(data.features);
          alert(`${data.features.length}件の特徴を生成しました。`);
        } else {
          console.log('Success is false, error:', data.error);
          alert(`エラー: ${data.error}`);
        }
      })
      .catch(error => {
        console.error('Error:', error);
        alert('AI生成中にエラーが発生しました。');
      })
      .finally(() => {
        if (loadingDiv) {
          loadingDiv.style.display = 'none';
        }
        button.disabled = false;
        button.innerHTML = originalText;
      });
    });
  }

  // 生成された特徴をフォームに入力
  function populateFeatures(features) {
    console.log('populateFeatures called with:', features);
    const container = document.getElementById('features-container');
    if (!container) {
      console.error('features-container not found');
      return;
    }
    
    container.innerHTML = '';
    featureIndex = 0;
    const categoryOptions = getCategoryOptions() || getStaticCategoryOptions();

    features.forEach((feature, index) => {
      const newRow = document.createElement('div');
      newRow.className = 'feature-row mb-3';
      newRow.innerHTML = `
        <div class="row">
          <div class="col-md-3">
            <select name="features[${index}][category_id]" class="form-select" required>
              ${categoryOptions}
            </select>
          </div>
          <div class="col-md-2">
            <select name="features[${index}][level]" class="form-select" required>
              <option value="">レベル</option>
              <option value="1" ${feature.level == 1 ? 'selected' : ''}>1（具体性が高い）</option>
              <option value="2" ${feature.level == 2 ? 'selected' : ''}>2（普通）</option>
              <option value="3" ${feature.level == 3 ? 'selected' : ''}>3（抽象度が高い）</option>
            </select>
          </div>
          <div class="col-md-6">
            <input type="text" name="features[${index}][feature]" class="form-control" value="${escapeHtml(feature.feature)}" placeholder="特徴を入力">
          </div>
          <div class="col-md-1">
            <button type="button" class="btn btn-danger remove-feature">削除</button>
          </div>
        </div>
      `;
      container.appendChild(newRow);
      
      // カテゴリを設定（カテゴリIDを直接設定、またはカテゴリ名からIDを取得）
      const categorySelectElement = newRow.querySelector('select[name$="[category_id]"]');
      console.log('Setting category for feature:', feature);
      console.log('Category select element:', categorySelectElement);
      console.log('Available options:', Array.from(categorySelectElement.options).map(o => ({value: o.value, text: o.text})));
      
      if (feature.category_id) {
        // カテゴリIDが直接提供されている場合
        console.log('Setting category_id:', feature.category_id);
        categorySelectElement.value = feature.category_id;
        console.log('Selected value after setting:', categorySelectElement.value);
      } else {
        // カテゴリ名からIDを取得
        console.log('Looking for category by name:', feature.category);
        for (let option of categorySelectElement.options) {
          if (option.text === feature.category) {
            console.log('Found matching category:', option.value, option.text);
            categorySelectElement.value = option.value;
            break;
          }
        }
      }
    });

    featureIndex = features.length;
  }

  function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }
}

// ページ遷移時に初期化フラグをリセット
document.addEventListener('turbo:before-cache', function() {
  if (document.body) {
    delete document.body.dataset.fighterFeaturesInitialized;
  }
});

// DOMContentLoadedとTurboの両方のイベントで初期化
document.addEventListener('DOMContentLoaded', initializeFighterFeatures);
document.addEventListener('turbo:load', initializeFighterFeatures);
document.addEventListener('turbo:render', initializeFighterFeatures);