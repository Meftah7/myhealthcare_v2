(() => {
  const failures=[],surfaces=[];
  for(const r of ['Doctor','Admin']){setRole(r);for(const p of [...nav().map(n=>n[0]),'login','analysis','rooms','billing']){go(p);const overflow=document.documentElement.scrollWidth>innerWidth+1;const theme=document.getElementById('theme').getBoundingClientRect();const visibleTheme=theme.width>=44&&theme.right<=innerWidth&&theme.left>=0;surfaces.push(r+'/'+p);if(overflow||!visibleTheme)failures.push({role:r,page:p,overflow,visibleTheme,width:innerWidth,scroll:document.documentElement.scrollWidth})}}
  setRole('Doctor');return JSON.stringify({width:innerWidth,surfaces:surfaces.length,failures});
})()
