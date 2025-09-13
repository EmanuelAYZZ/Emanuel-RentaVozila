window.addEventListener("message", (event) => {
  if (event.data.akcija === "otvori") {
    document.getElementById("vozila").innerHTML = "";
    event.data.vozila.forEach(v => {
      const btn = document.createElement("button");
      btn.innerText = v.label + " - $" + v.cijena;
      btn.onclick = () => {
        fetch(`https://${GetParentResourceName()}/rentaj`, {
          method: "POST",
          body: JSON.stringify({model:v.model, cijena:v.cijena}),
          headers: {"Content-Type":"application/json"}
        });
        zatvori();
      };
      document.getElementById("vozila").appendChild(btn);
    });
    document.getElementById("panel").style.display = "block";
  }
});

function zatvori() {
  document.getElementById("panel").style.display = "none";
  fetch(`https://${GetParentResourceName()}/zatvori`, {
    method:"POST", body: JSON.stringify({})
  });
}
