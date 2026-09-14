export function folderReview(files) {
  const root={name:'Scanned Swift folders',children:[],files:[]};
  const paths=new Set(files.map(f=>f.path));
  for (const file of files) {
    const parts=file.path.split('/');const name=parts.pop();let node=root;
    for(const part of parts) {
      let child=node.children.find(c=>c.name===part);
      if(!child){child={name:part,children:[],files:[]};node.children.push(child);}
      node=child;
    }
    node.files.push({name,path:file.path});
  }
  const check=(title,matched,detail)=>({title,matched,detail});
  const ui=files.filter(f=>/(?:^|\/)(?:1 - View|UI|Presentation|Views)\//.test(f.path));
  const model=files.filter(f=>/(?:^|\/)(?:2 - AppModel|Model|Domain)\//.test(f.path));
  const managers=files.filter(f=>f.path.endsWith('ViewModel.swift'));
  const paired=managers.filter(f=>paths.has(f.path.replace(/ViewModel\.swift$/,'View.swift')));
  return {root,checks:[
    check('UI has a named folder',ui.length>0,ui.length+' Swift files under a recognised UI folder.'),
    check('Model has a named folder',model.length>0,model.length+' Swift files under a recognised Model folder.'),
    check('Features are grouped by name',files.some(f=>/(?:^|\/)Features\/[^/]+\//.test(f.path)),'Looks for a Features folder with named subfolders.'),
    check('AppModel is easy to locate',files.some(f=>/(?:^|\/)(?:AppModel)\.swift$/.test(f.path)),'Looks for the composition-root filename, not its implementation.'),
    {title:'ViewModels sit beside their Views',matched:managers.length?paired.length===managers.length:null,detail:managers.length?paired.length+' of '+managers.length+' ViewModels have a same-named View in the same folder.':'No ViewModel-named files found.'}
  ]};
}
